context Blinkbox::CommonMapping do
  before :each do
    @mappings_url = "http://storage-service.example.com/mappings"
    stub_request(:get, @mappings_url).to_return(body: proc { mappings_response.to_json })
    @instance = described_class.new(
      "http://storage-service.example.com",
      service_name: "tests",
      schema_root: nil
    )
    # Reset the request history
    WebMock::RequestRegistry.instance.reset!
  end

  describe "#retrieve_mapping!" do
    it "must download the mapping file and update the mapping data" do
      allow(@instance).to receive(:update_mapping!).and_return(true)
      expect(@instance.retrieve_mapping!).to eq(true)
      expect(a_request(:get, @mappings_url)).to have_been_made.once
      expect(@instance).to have_received(:update_mapping!)
    end

    it "must raise StorageServiceUnavailableError if the storage service is unavailable" do
      stub_request(:get, @mappings_url).to_timeout
      allow(@instance).to receive(:update_mapping!)
      expect {
        @instance.retrieve_mapping!
      }.to raise_error(Blinkbox::StorageServiceUnavailableError)
      expect(@instance).to_not have_received(:update_mapping!)
      expect(a_request(:get, @mappings_url)).to have_been_made.once
    end
  end
end