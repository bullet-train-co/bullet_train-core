require "test_helper"
require "generators/super_scaffold/incoming_webhooks/incoming_webhooks_generator"

class SuperScaffold::IncomingWebhooksGeneratorTest < Rails::Generators::TestCase
  tests SuperScaffold::IncomingWebhooksGenerator
  destination Rails.root.join("tmp/generators")
  setup :prepare_destination

  # test "generator runs without errors" do
  #   assert_nothing_raised do
  #     run_generator ["arguments"]
  #   end
  # end
end
