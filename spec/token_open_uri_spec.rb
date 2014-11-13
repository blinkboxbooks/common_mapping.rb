require "tempfile"

context Blinkbox::CommonMapping do
  before :each do
    @instance = described_class.allocate
  end

  describe "#open_uri (file URIs)" do
    it "must return a File object instance for the given file" do
      tmp = Tempfile.new("test_file")
      begin
        data = "Some data"
        tmp.write data
        tmp.close
        uri = URI.parse("file://#{tmp.path}")
        io = @instance.send(:open_uri, uri)
        expect(io.read).to eq(data)
      ensure
        tmp.unlink
      end
    end

    it "must return a File object instance for files with URI escaped names" do
      tmp = Tempfile.new("tëst filé")
      begin
        data = "Some data"
        tmp.write data
        tmp.close
        uri = URI.parse("file://#{URI.encode(tmp.path)}")
        io = @instance.send(:open_uri, uri)
        expect(io.read).to eq(data)
      ensure
        tmp.unlink
      end
    end

    it "must raise MissingAssetError if the file doesn't exist" do
      expect {
        @instance.send(:open_uri, URI("file:///this/file/doesnt/exist/849283nsdviugewt"))
      }.to raise_error(Blinkbox::MissingAssetError)
    end
  end

  describe "#open_uri (http URIs)" do
    it "must download the file and return an IO object referencing the data" do
      uri = URI.parse("http://data.example.com/file.txt")
      data = "This is the content of the file"
      stub_request(:get, uri.to_s).to_return(body: data)
      io = @instance.send(:open_uri, uri)
      expect(io.read).to eq(data)
    end

    [400, 404, 500].each do |code|
      it "must raise a MissingAssetError if the http server responds with #{code}" do
        uri = URI.parse("http://data.example.com/file-#{code}.txt")
      stub_request(:get, uri.to_s).to_return(status: code)
      expect {
        @instance.send(:open_uri, uri)
      }.to raise_error(Blinkbox::MissingAssetError)
      end
    end
  end
end