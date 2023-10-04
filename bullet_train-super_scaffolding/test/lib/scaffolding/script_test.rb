require "test_helper"

require_relative "../../../lib/scaffolding"

class SuperScaffoldingScriptTest < ActiveSupport::TestCase
  test "returns true when the attribute type is valid" do
    assert Scaffolding.valid_attribute_type?("boolean")
  end

  test "returns true when the attribute type is valid with a class name" do
    assert Scaffolding.valid_attribute_type?("super_select{class_name=Membership}")
  end

  test "raises an error when the attribute type is invalid" do
    refute Scaffolding.valid_attribute_type?("string")
  end

  test "raises an error when the attribute type is invalid with a class name" do
    refute Scaffolding.valid_attribute_type?("string{class_name=Membership}")
  end
end
