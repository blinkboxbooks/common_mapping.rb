context Blinkbox::CommonMapping do
  before :each do
    stub_request(:get, "http://storage-service.example.com/mappings").to_return(body: proc { mappings_response.to_json })
    @instance = described_class.new(
      "http://storage-service.example.com",
      service_name: "tests",
      schema_root: nil
    )
  end

  describe "#open (with block)" do
    it "must return an IO type object given a valid token referencing File resources" do
      content = "Content of file"
      token = create_token_for(create_uri_for(content, type: "file"))
      @instance.open(token) do |io|
        expect(io.read).to eq(content)
      end
    end

    it "must return an IO type object given a valid token referencing HTTP resources" do
      content = "Content of file"
      uri = create_uri_for(content, type: "http")
      token = create_token_for(uri)
      @instance.open(token) do |io|
        expect(io.read).to eq(content)
      end
    end
  end

  describe "#open (without block)" do
    it "must return an IO type object given a valid token referencing File resources" do
      content = "Content of file"
      token = create_token_for(create_uri_for(content, type: "file"))
      io = @instance.open(token)
      expect(io.read).to eq(content)
    end

    it "must return an IO type object given a valid token referencing HTTP resources" do
      content = "Content of file"
      uri = create_uri_for(content, type: "http")
      token = create_token_for(uri)
      io = @instance.open(token)
      expect(io.read).to eq(content)
    end

    it "must pick the first provider to retrieve data from" do
      content = "Content of file"
      uris = [
        create_uri_for(content, type: "http"),
        create_uri_for(content, type: "http")
      ]
      token = create_token_for(uris)
      io = @instance.open(token)
      expect(io.read).to eq(content)
      expect(a_request(:get, uris[0])).to have_been_made.once
      expect(a_request(:get, uris[1])).to_not have_been_made
    end

    describe "assets missing from providers" do
      it "must try the first provider marked as working in the given asset's status" do
        content = "Content of file"
        uris = [
          create_uri_for(content, type: "http", respond_with: { status: 404 }),
          create_uri_for(content, type: "http", respond_with: { status: 404 }),
          create_uri_for(content, type: "http"),
          create_uri_for(content, type: "http")
        ]
        token = create_token_for(uris)
        token_status_uri = "http://storage-service.example.com/resources/#{token}"
        status_response = {
          token: token,
          label: @labels.first[:label],
          providers: Hash[@labels.first[:providers].map { |name, url|
            [name, { available: !uris[0..1].include?(url) }]
          }]
        }
        stub_request(:get, token_status_uri).to_return(body: status_response.to_json)

        io = @instance.open(token)
        # Must have tried the first provider
        expect(a_request(:get, uris[0])).to have_been_made.once
        # And hit the status page
        expect(a_request(:get, token_status_uri)).to have_been_made
        # And finally queried the first active provider
        expect(a_request(:get, uris[2])).to have_been_made
        # But not the second active provider
        expect(a_request(:get, uris[3])).to_not have_been_made
      end
    end
  end
end