context Blinkbox::CommonMapping do
  describe "#new" do
    it "must retrieve the latest mappings on initialisation" do
      url = "http://storage-service.example.com/mappings"
      stub_request(:get, url).to_return(body: proc { mappings_response.to_json })
      @instance = described_class.new(
        "http://storage-service.example.com",
        service_name: "tests",
        schema_root: nil
      )
      expect(a_request(:get, url)).to have_been_made.once
    end

    it "must create a temporary, exclusive queue for mapping updates" do
      url = "http://storage-service.example.com/mappings"
      stub_request(:get, url).to_return(body: proc { mappings_response.to_json })
      service_name = "tests"
      @instance = described_class.new(
        "http://storage-service.example.com",
        service_name: service_name,
        schema_root: nil
      )
      expect(@fake_queue_class).to have_received(:new).with(
        start_with("#{service_name}.mapping_updates."),
        hash_including(
          exchange: "Mapping",
          bindings: [{"content-type"=>"application/vnd.blinkbox.books.mapping.update.v1+json"}],
          exclusive: true,
          temporary: true,
          dlx: nil
        )
      )
      expect(@fake_queue).to have_received(:subscribe).with(block: false)
    end
  end
end