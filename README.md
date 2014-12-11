# Blinkbox::CommonMapping

Deals with blinkbox Books virtual URIs and acts like a local `File` object.

```ruby
mapper = Mappings.new(
  "http://quatermaster.blinkbox.local",
  service_name: "Labs/example_code"
)

mapper.open("bbbmap::testfile:/some/path/component.epub") do |io|
  p io
  # This is a Tempfile object, interact with it as you wish!
end
# Temporary file has been deleted
```
