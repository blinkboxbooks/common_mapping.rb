context Blinkbox::CommonMapping do
  before :each do
    @instance = described_class.allocate
  end

  describe "message queue mapping updater" do
    before :each do
      url = "http://storage-service.example.com/mappings"
      stub_request(:get, "http://storage-service.example.com/mappings").to_return(body: proc { mappings_response.to_json })
      @instance = described_class.new(
        "http://storage-service.example.com",
        service_name: "tests",
        schema_root: nil
      )
    end

    it "must update the mapping when a new message is delivered to the queue" do
      data = "mapping data"
      timestamp = Time.now
      allow(@instance).to receive(:update_mapping!)

      expect(deliver_message!(data, timestamp: timestamp)).to eq(:ack)
      expect(@instance).to have_received(:update_mapping!).with(timestamp, data)
    end
  end
end