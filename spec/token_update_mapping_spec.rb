context Blinkbox::CommonMapping do
  before :each do
    @instance = described_class.allocate
  end

  describe "#update_mapping!" do
    it "must store the mapping file if there is no stored mapping" do
      mapping = { a: "mapping hash" }
      timestamp = Time.now
      @instance.send('update_mapping!', timestamp, mapping)
      expect(@instance.instance_variable_get('@mapping')).to eq(
        data: mapping,
        timestamp: timestamp
      )
    end

    it "must store the mapping file if the stored mapping is older" do
      mapping = { a: "mapping hash" }
      timestamp = Time.now

      @instance.instance_variable_set('@mapping', {
        data: "old",
        timestamp: timestamp - 100
      })

      @instance.send('update_mapping!', timestamp, mapping)
      expect(@instance.instance_variable_get('@mapping')).to eq(
        data: mapping,
        timestamp: timestamp
      )
    end

    it "must not store the mapping file if the stored mapping is newer" do
      mapping = { a: "mapping hash" }
      newer_mapping = { a: "a newer mapping hash" }
      timestamp = Time.now
      newer_timestamp = timestamp + 100

      @instance.instance_variable_set('@mapping', {
        data: newer_mapping,
        timestamp: newer_timestamp
      })

      @instance.send('update_mapping!', timestamp, mapping)
      expect(@instance.instance_variable_get('@mapping')).to eq(
        data: newer_mapping,
        timestamp: newer_timestamp
      )
    end
  end
end