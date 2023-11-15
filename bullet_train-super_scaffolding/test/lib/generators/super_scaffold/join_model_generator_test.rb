require "test_helper"
require "generators/super_scaffold/join_model/join_model_generator"

class JoinModelGeneratorTest < Rails::Generators::TestCase
  tests JoinModelGenerator
  destination Rails.root.join("tmp/generators")
  setup :prepare_destination

  # test "generator runs without errors" do
  #   assert_nothing_raised do
  #     run_generator ["arguments"]
  #   end
  # end
end
