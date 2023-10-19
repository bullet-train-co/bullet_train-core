require "test_helper"
require "generators/bullet_train/join_model/join_model_generator"

class BulletTrain::JoinModelGeneratorTest < Rails::Generators::TestCase
  tests BulletTrain::JoinModelGenerator
  destination Rails.root.join("tmp/generators")
  setup :prepare_destination

  # test "generator runs without errors" do
  #   assert_nothing_raised do
  #     run_generator ["arguments"]
  #   end
  # end
end
