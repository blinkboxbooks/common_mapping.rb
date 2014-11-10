context Blinkbox::CommonMapping do
  before :each do
    stub_request(:get, "http://storage-service.example.com/mappings").to_return(body: proc { mappings_response.to_json })
    @instance = described_class.new(
      "http://storage-service.example.com",
      service_name: "tests",
      schema_root: nil
    )
  end

  describe "#status" do
    it "must return the status of valid token" do
      token = "bbbmap:label:whatever"
      status_doc = { "this" => "gets passed back directly" }
      stub_request(:get, "http://storage-service.example.com/resources/#{token}")
        .to_return(body: status_doc.to_json)
      expect(@instance.status(token)).to eq(status_doc)
    end

    it "must raise an InvalidTokenError for an invalid token" do
      expect{
        @instance.status("http://not.a/token")
      }.to raise_error(Blinkbox::InvalidTokenError)
    end
  end
end