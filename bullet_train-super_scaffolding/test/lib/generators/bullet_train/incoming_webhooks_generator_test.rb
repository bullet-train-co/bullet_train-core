require "test_helper"
require "generators/bullet_train/incoming_webhooks/incoming_webhooks_generator"

class BulletTrain::IncomingWebhooksGeneratorTest < Rails::Generators::TestCase
  tests BulletTrain::IncomingWebhooksGenerator
  destination Rails.root.join("tmp/generators")
  setup :prepare_destination

  # test "generator runs without errors" do
  #   assert_nothing_raised do
  #     run_generator ["arguments"]
  #   end
  # end
end
