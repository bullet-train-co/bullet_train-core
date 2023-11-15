require "test_helper"
require "generators/super_scaffold/super_scaffold_generator"

class SuperScaffoldGeneratorTest < Rails::Generators::TestCase
  tests SuperScaffoldGenerator
  destination Rails.root.join("tmp/generators")
  setup :prepare_destination

  # test "generator runs without errors" do
  #   assert_nothing_raised do
  #     run_generator ["arguments"]
  #   end
  # end
end
