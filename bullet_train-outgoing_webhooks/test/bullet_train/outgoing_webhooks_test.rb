require "test_helper"

class BulletTrain::OutgoingWebhooksTest < ActiveSupport::TestCase
  test "it has a version number" do
    refute_nil BulletTrain::OutgoingWebhooks::VERSION
  end
end
