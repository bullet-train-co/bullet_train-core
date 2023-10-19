require "test_helper"
require "generators/bullet_train/oauth_provider/oauth_provider_generator"

class SuperScaffold::OauthProviderGeneratorTest < Rails::Generators::TestCase
  tests SuperScaffold::OauthProviderGenerator
  destination Rails.root.join("tmp/generators")
  setup :prepare_destination

  # test "generator runs without errors" do
  #   assert_nothing_raised do
  #     run_generator ["arguments"]
  #   end
  # end
end
