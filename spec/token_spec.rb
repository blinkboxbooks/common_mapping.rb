context Blinkbox::CommonMapping do
  describe "#open" do
    it "must return an IO object given a valid token referencing File resources"
    it "must return an IO object given a valid token referencing HTTP resources"
    it "must pick the first provider to retrieve data from"

    describe "assets missing from providers" do
      it "must get the asset's status if the request fails"
      it "must try the first provider marked as working in the given asset's status"
    end
  end
end