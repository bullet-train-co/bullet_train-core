require "test_helper"
require "generators/super_scaffold/field/field_generator"

class FieldGeneratorTest < Rails::Generators::TestCase
  tests FieldGenerator
  destination Rails.root.join("tmp/generators")
  setup :prepare_destination

  # test "generator runs without errors" do
  #   assert_nothing_raised do
  #     run_generator ["arguments"]
  #   end
  # end
end
