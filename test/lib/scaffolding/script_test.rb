require "test_helper"
require "minitest/spec"

require_relative "../../../lib/scaffolding"

describe "Super Scaffolding Script" do
  it "returns true when the attribute type is valid" do
    assert Scaffolding.valid_attribute_type?("boolean")
  end

  it "raises an error when the attribute type is invalid" do
    refute Scaffolding.valid_attribute_type?("string")
  end
end
