require "uri"
require "json"
require "time"
require "socket"
require "net/http"
require "tempfile"
require "blinkbox/common_messaging"

module Blinkbox
  class CommonMapping
    VERSION = begin
      File.read(File.join(__dir__, "../../VERSION")).strip
    rescue Errno::ENOENT
      "0.0.0-unknown"
    end

    # Set a logger to send all log messages to
    #
    # @param [:debug,:info,:warn,:error,:fatal] logger A logger instance.
    def self.logger=(logger)
      @@logger = logger
    end

    # NullLogger by default
    @@logger = Class.new {
      def debug(*); end
      def info(*); end
      def warn(*); end
      def error(*); end
      def fatal(*); end
    }.new

    # Initializing a mapper will retrieve the mapping file from the specified storage service and set up an exclusive queue
    # to receive updates which might occur while this instance is in use.
    #
    # @param [String] storage_service_url The Base URL for the storage service.
    # @param [String] :service_name The name of your service. Defines the name of the mapping updates queue.
    # @param [String, nil] :schema_root If not nil, the location (relative to the current directory) of the schema root (mapping/update/v1.schema.json will be used to validate messages).
    # @param [Integer] :mapping_timeout The length of time before a new mapping file is requested from the storage service.
    def initialize(storage_service_url, service_name: raise(ArgumentError, "A service name is required"), schema_root: "schema", mapping_timeout: 7 * 24 * 3600)
      @ss = URI.parse(storage_service_url)
      @service_name = service_name
      uid = [Socket.gethostname, Process.pid].join("$")
      queue_name = "#{service_name.tr('/', '.')}.mapping_updates.#{uid}"

      @queue = CommonMessaging::Queue.new(
        queue_name,
        exchange: "Mapping",
        bindings: [{ "content-type" => "application/vnd.blinkbox.books.mapping.update.v1+json" }],
        prefetch: 1,
        exclusive: true,
        temporary: true,
        dlx: nil
      )

      @timeout = mapping_timeout

      opts = { block: false }
      if !schema_root.nil?
        CommonMessaging.init_from_schema_at(File.join(schema_root, "mapping"), schema_root)
        opts[:accept] = [CommonMessaging::MappingUpdateV1]
      end

      # We're about to request the latest mapping file, so we don't need any of the ones on the queue.
      @queue.purge!
      @queue.subscribe(opts) do |metadata, update|
        next :reject unless metadata[:timestamp].is_a?(Time)
        update_mapping!(metadata[:timestamp], update)
        :ack
      end

      @@logger.debug "Queue #{queue_name} created, bound and subscribed to"
      retrieve_mapping!
      @@logger.info "Mapping initialized"
    end

    # Opens a given token and returns an IO object for the associated asset or - if a block
    # is passed - yields with the IO object as the only argument.
    # 
    # @param [String] token The token referring to the asset to be opened
    # @raise InvalidTokenError if the given token string isn't a valid token
    def open(token)
      raise InvalidTokenError unless valid_token?(token)
      @@logger.debug "Opening #{token}"
      locations = map(token)
      @@logger.debug "Locations for #{token} are: #{locations.inspect}"
      # TODO: We currently assume the first is the best. Later iterations of this library may be more intelligent
      while locations.size > 0
        provider, uri = locations.shift
        @@logger.debug "Trying #{uri} from #{provider}"
        begin
          io = open_uri(URI.parse(uri))
          return io if !block_given?
          yield(io)
          io.close
          return nil
        rescue
          # There was a problem with this provider file, register it and move on to another
          status = retrieve_status(token, provider_failure: provider)
          available_providers = status['providers'].map { |this_provider, this_status|
            this_status['available'] ? this_provider : nil
          }.compact
          locations.delete_if { |p, u|
            !(status['providers'][p] && status['providers'][p]['available'])
          }
        end
      end
      raise MissingAssetError, "The asset for #{token} could not be downloaded from anywhere."
    end

    # Gets information about a specific token.
    #
    # @param [String] token The token for the asset to get the status of
    def status(token)
      # Duplicate method so the external API can't register a provider failure
      retrieve_status(token)
    end

    # Collects the mappings from the storage service specified when initialised.
    # 
    # @return [Boolean] Returns true if the mapping file was updated, false if the mapping already stored was the same or more recent.
    # @raise StorageServiceUnavailableError if the response from the server isn't 200, isn't JSON or (if the schema are available) isn't a valid mapping document.
    def retrieve_mapping!
      response = ss_get("/mappings")
      raise StorageServiceUnavailableError, "Storage service gave #{response.code} response code, cannot update the mapping details." unless response.code == "200"
      mapping = JSON.parse(response.body)
      # This will raise a JSON::Schema::ValidationError if the mapping file isn't valid
      CommonMessaging::MappingUpdateV1.new(mapping) if CommonMessaging.const_defined?('MappingUpdateV1')
      timestamp = response['Date'].nil? ? Time.now : Time.parse(response['Date'])
      update_mapping!(timestamp, mapping)
    rescue JSON::ParserError, JSON::Schema::ValidationError
      raise StorageServiceUnavailableError, "The response from the storage service wasn't a valid mapping update."
    end

    def inspect
      "<Token Mapper: #{@ss.host}>"
    end

    private

    # Stores a retrieved mapping file along with the timestamp
    #
    # @param [Time] timestamp The timestamp at which the given mapping was accurate
    # @param [Hash, CommonMessaging::MappingUpdateV1] mapping The mapping file which needs to be stored
    # @return [Boolean] Returns true if the mapping file was updated, false if the mapping already stored was the same or more recent.
    def update_mapping!(timestamp, mapping)
      return false if (!@mapping.nil? && timestamp < @mapping[:timestamp])
      return false if (!@mapping.nil? && @mapping[:data] == mapping)
      @mapping = {
        data: mapping,
        timestamp: timestamp
      }
      true
    end

    # Gets the status of a specific token, optionally recording that a provider has failed for a specific
    # asset if specified.
    #
    # @return [nil] if the token does not exist
    # @return [Hash] details of the asset
    def retrieve_status(token, provider_failure: nil)
      raise InvalidTokenError unless valid_token?(token)
      res = ss_get("/resources/#{token}")
      return nil if res.code == "404"
      # TODO: Deal with other response codes
      raise StorageServiceUnavailableError, "Storage service responded with #{res.code}" unless res.code == "200"
      JSON.parse(res.body)
    end

    # TODO: Deal with unlinking tempfiles
    def open_uri(uri)
      case uri.scheme
      when "file"
        path = URI.decode(uri.path)
        @@logger.debug "Attempting to open #{path}"
        raise MissingAssetError unless File.exist?(path)
        io = File.open(path)
      when "http", "https"
        io = Tempfile.new("common_mapping_file")
        Net::HTTP.start(uri.host, uri.port) do |http|
          http.request_get(uri.path) do |resp|
            raise MissingAssetError, "Received a #{resp.code} while trying to retrieve #{uri}" if resp.code != "200"
            resp.read_body do |segment|
              io.write(segment)
            end
          end
        end
        io.rewind
      else
        raise NotImplementedError
      end
      io
    end

    def ss_get(path)
      @http ||= Net::HTTP.new(@ss.host, @ss.port)
      request = Net::HTTP::Get.new(path)
      request.initialize_http_header({"User-Agent" => "common_mapping.rb/#{VERSION}"})
      @http.request(request)
    rescue Timeout::Error
      raise StorageServiceUnavailableError, "A request to the storage service timed out"
    end

    # @param [String] token The token that wants to be checked
    # @return [Boolean] Whether the token is valid or not
    def valid_token?(token)
      uri = URI(token)
      uri.scheme == "bbbmap"
    rescue URI::InvalidURIError
      false
    end

    # Uses the mapping file retrieved to convert a token into URLs. The first item in the hash
    # will be the first provider listed in the first matched label group etc.
    #
    # Will retrieve the mapping afresh if the mapping data has expired (is older than the
    # timeout value used to initialise this object)
    #
    # @param [URI] token The token (as a URI object) to look up.
    # @raise UnknownLabelError if no mappings exist for the token given.
    # @raise InvalidTokenError if the given token string isn't a valid token
    # @return [Hash] A hash of provider names (key) to URLs (value) for this asset.
    def map(token)
      raise InvalidTokenError unless valid_token?(token)
      retrieve_mapping! if (Time.now.to_i - @mapping[:timestamp].to_i > @timeout)
      @@logger.debug "Using mapping: #{@mapping[:data]}"
      matched_providers = {}
      @mapping[:data].each do |label_map|
        re = Regexp.new(label_map['extractor'])
        if token.match(re)
          @@logger.debug "Using #{label_map['label']}"
          capture_groups = Hash[
            Regexp.last_match.names.zip(Regexp.last_match.captures)
          ].inject({}){ |memo, (k, v)|
            memo[k.to_sym] = v
            memo
          }
          label_map['providers'].each_pair do |name, url_template|
            # If there are multiple matching label_maps then providers from the first will take priority over later ones.
            begin
              matched_providers[name] ||= (url_template % capture_groups)
            rescue
            end
          end
        end
      end
      matched_providers
    end
  end

  class MissingAssetError < RuntimeError; end
  class UnknownLabelError < RuntimeError; end
  class InvalidTokenError < URI::InvalidURIError; end
  class StorageServiceUnavailableError < RuntimeError; end
end
