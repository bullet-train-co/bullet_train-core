require "test_helper"
require "generators/super_scaffold/oauth_provider/oauth_provider_generator"

class OauthProviderGeneratorTest < Rails::Generators::TestCase
  tests OauthProviderGenerator
  destination Rails.root.join("tmp/generators")
  setup :prepare_destination

  # test "generator runs without errors" do
  #   assert_nothing_raised do
  #     run_generator ["arguments"]
  #   end
  # end
end
