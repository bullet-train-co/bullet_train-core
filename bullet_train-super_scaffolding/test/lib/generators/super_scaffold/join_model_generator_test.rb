require "test_helper"
require "generators/bullet_train/join_model/join_model_generator"

class SuperScaffold::JoinModelGeneratorTest < Rails::Generators::TestCase
  tests SuperScaffold::JoinModelGenerator
  destination Rails.root.join("tmp/generators")
  setup :prepare_destination

  # test "generator runs without errors" do
  #   assert_nothing_raised do
  #     run_generator ["arguments"]
  #   end
  # end
end
