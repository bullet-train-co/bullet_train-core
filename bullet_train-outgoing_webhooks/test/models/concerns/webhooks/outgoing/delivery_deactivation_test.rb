require "test_helper"
require "minitest/mock"
require "setup/create_webhooks_test_helper"

class Webhooks::Outgoing::DeliveryDeactivationTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include CreateWebhooksTestHelpers

  setup do
    @team = Team.create!(name: "test-team")
    @endpoint = create_endpoint(team: @team)
    @delivery = create_delivery(endpoint: @endpoint)
  end

  test "#deliver_async calls endpoint.handle_exhausted_delivery_attempts when all delivery attempts have failed" do
    # Create max available attempts to not trigger deactivation yet
    create_delivery_attempts(@delivery, @delivery.max_attempts)

    assert_not @delivery.failed?, "Delivery should not be failed"
    assert @delivery.still_attempting?, "Delivery should be still attempting"

    # Create the last failed attempt
    create_delivery_attempts(@delivery, 1, response_code: 500, error_message: "Server error")

    assert @delivery.failed?, "Delivery should be failed"
    assert_not @delivery.still_attempting?, "Delivery should not be still attempting"

    # Mock the endpoint to verify handle_exhausted_delivery_attempts is called
    endpoint_mock = Minitest::Mock.new
    endpoint_mock.expect :handle_exhausted_delivery_attempts, nil

    @delivery.stub(:endpoint, endpoint_mock) do
      @delivery.deliver_async
    end

    endpoint_mock.verify
    assert_no_enqueued_jobs only: Webhooks::Outgoing::DeliveryJob
  end

  test "#deliver_async does not call endpoint.handle_exhausted_delivery_attempts when still attempting" do
    # Create fewer attempts than max to ensure delivery is still attempting
    create_delivery_attempts(@delivery, 2)

    assert @delivery.still_attempting?, "Delivery should still be attempting"
    assert_not @delivery.failed?, "Delivery should not be failed"

    endpoint_mock = Minitest::Mock.new

    # We don't expect handle_exhausted_delivery_attempts to be called
    @delivery.stub(:endpoint, endpoint_mock) do
      assert_enqueued_jobs 1, only: Webhooks::Outgoing::DeliveryJob do
        @delivery.deliver_async
      end
    end

    endpoint_mock.verify
  end
end
