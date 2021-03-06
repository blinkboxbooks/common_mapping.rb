$LOAD_PATH.unshift File.join(__dir__, "../lib")
require "blinkbox/common_mapping"
require "rspec/mocks"
require "webmock/rspec"
require "securerandom"
require "tempfile"

module Helpers
  def create_token_for(*uris, label: "label-" << (@labels.size + 1).to_s)
    token = "bbbmap:#{label}:#{SecureRandom.hex}"
    @labels.push(
      label: label,
      extractor: "^bbbmap:#{label}:.+$",
      providers: Hash[uris.flatten.map.with_index { |uri, i|
        ["provider-#{i+1}", uri]
      }]
    )
    @instance.retrieve_mapping!
    token
  end

  def create_uri_for(content, type: "file", respond_with: { body: content })
    @created_uris += 1
    case type
    when "file"
      tmp = Tempfile.new("testfile")
      tmp.write(content)
      tmp.rewind
      return "file://#{URI.encode(tmp.path)}"
    when "http"
      uri = URI::HTTP.build(host: "data.example.com", path: "/created-uri-#{@created_uris}")
      stub_request(:get, uri.to_s).to_return(respond_with)
      return uri.to_s
    end
  end

  def mappings_response
    @labels
  end

  def deliver_message!(string, extra_metadata = {})
    metadata = {
      timestamp: Time.now
    }.merge(extra_metadata)
    @subscribe_block.call(metadata, string)
  end
end

RSpec.configure do |c|
  c.include Helpers

  c.before :each do
    @labels = []
    @created_uris = 0

    queue_class = 'Blinkbox::CommonMessaging::Queue'
    @fake_queue = instance_double(queue_class)
    @fake_queue_class = double(queue_class, :new => @fake_queue)

    stub_const(queue_class, @fake_queue_class)
    @subscribe_block = proc {}
    allow(@fake_queue).to receive(:purge!)
    allow(@fake_queue).to receive(:subscribe) do |_opts, &block|
      @subscribe_block = block
    end
  end
end