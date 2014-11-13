require "tempfile"

context Blinkbox::CommonMapping do
  before :each do
    stub_request(:get, "http://storage-service.example.com/mappings").to_return(body: proc { mappings_response.to_json })
    @instance = described_class.new(
      "http://storage-service.example.com",
      service_name: "tests",
      schema_root: nil
    )
  end

  describe "#map" do
    it "must list providers for the label associated with the given token" do
      @labels = [
        {
          label: "label",
          extractor: "^bbbmap:label:(?<path>.+)$",
          providers: {
            alpha: "http://alpha.example.com/%{path}",
            beta: "http://beta.example.com/extra/%{path}"
          }
        }
      ]
      # Force an update of the mapping file
      @instance.retrieve_mapping!

      expect(@instance.send(:map, "bbbmap:label:abcdef123456")).to eq(
        "alpha" => "http://alpha.example.com/abcdef123456",
        "beta" => "http://beta.example.com/extra/abcdef123456"
      )
    end

    it "must return an empty hash if the token doesn't match any mappings" do
      # Load no mappings
      expect(@instance.send(:map, "bbbmap:label:whatever")).to eq({})
    end

    it "must request new mappings if the timeout has been reached" do
      @instance.instance_variable_get('@mapping')[:timestamp] = Time.at(0)
      allow(@instance).to receive(:retrieve_mapping!)
      @instance.send(:map, "bbbmap:label:whatever")
      expect(@instance).to have_received(:retrieve_mapping!)
    end

    it "must raise InvalidTokenError if the token given is not valid" do
      expect {
        @instance.send(:map, "invalid token")
      }.to raise_error(Blinkbox::InvalidTokenError)
    end
  end
end