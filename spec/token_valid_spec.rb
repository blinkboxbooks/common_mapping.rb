require "tempfile"

context Blinkbox::CommonMapping do
  describe "#valid_token?" do
    it "must return true for a valid token" do
      expect(described_class.allocate.send(:valid_token?, "bbbmap:label:something_else")).to eq(true)
    end

    it "must return false for non-bbb URIs" do
      expect(described_class.allocate.send(:valid_token?, "http://whatever")).to eq(false)
    end

    it "must return false for non-URIs" do
      expect(described_class.allocate.send(:valid_token?, "not a uri")).to eq(false)
    end
  end
end