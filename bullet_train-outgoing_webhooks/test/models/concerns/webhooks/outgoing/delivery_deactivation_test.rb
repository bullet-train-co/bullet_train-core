require "test_helper"
require "minitest/mock"

class Webhooks::Outgoing::DeliveryDeactivationTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def create_user(options = {})
    User.create!(
      email: options[:email] || "test@example.com",
      password: options[:password] || "password",
    )
  end

  def create_endpoint(options = {})
    Webhooks::Outgoing::Endpoint.create!(
      url: options[:url] || "https://example.com/webhook",
      name: options[:name] || "test",
      team: options[:team] || @team,
      event_type_ids: options[:event_type_ids] || ["fake-thing.create"],
      deactivation_limit_reached_at: options[:deactivation_limit_reached_at] || nil,
      deactivated_at: options[:deactivated_at] || nil,
    )
  end

  def create_event(options = {})
    Webhooks::Outgoing::Event.create!(
      subject: options[:subject] || create_user,
      event_type_id: options[:event_type_id] || "fake-thing.create",
      team: options[:team] || @team,
      payload: options[:payload] || {data: "test"},
      api_version: options[:api_version] || 1,
    )
  end

  def create_delivery(options = {})
    Webhooks::Outgoing::Delivery.create!(
      endpoint: options[:endpoint] || create_endpoint,
      event: options[:event] || create_event,
      endpoint_url: options[:endpoint_url] || "https://example.com/webhook",
      delivered_at: options[:delivered_at] || nil,
      created_at: options[:created_at] || Time.current
    )
  end

  def create_delivery_attempts(delivery, count, options = {})
    count.times do |i|
      delivery.delivery_attempts.create!(
        attempt_number: i + 1,
        response_code: options[:response_code] || 500,
        error_message: options[:error_message] || "Server error",
        created_at: options[:created_at] || Time.current
      )
    end
  end

  def created_at_that_considered_failed
    Webhooks::Outgoing::Delivery.max_attempts_period.ago - 1.hour
  end

  setup do
    @team = Team.create!(name: "test-team")
    @endpoint = create_endpoint(team: @team)
    @delivery = create_delivery(endpoint: @endpoint)
  end

  test "#deliver_async calls endpoint.deactivation_processing when all delivery attempts have failed" do
    # Create max available attempts to not trigger deactivation yet
    create_delivery_attempts(@delivery, @delivery.max_attempts)

    assert_not @delivery.failed?, "Delivery should not be failed"
    assert @delivery.still_attempting?, "Delivery should be still attempting"

    # Create the last failed attempt
    create_delivery_attempts(@delivery, 1, response_code: 500, error_message: "Server error")

    assert @delivery.failed?, "Delivery should be failed"
    assert_not @delivery.still_attempting?, "Delivery should not be still attempting"

    # Mock the endpoint to verify deactivation_processing is called
    endpoint_mock = Minitest::Mock.new
    endpoint_mock.expect :deactivation_processing, nil

    @delivery.stub(:endpoint, endpoint_mock) do
      @delivery.deliver_async
    end

    endpoint_mock.verify
    assert_no_enqueued_jobs only: Webhooks::Outgoing::DeliveryJob
  end

  test "#deliver_async does not call endpoint.deactivation_processing when still attempting" do
    # Create fewer attempts than max to ensure delivery is still attempting
    create_delivery_attempts(@delivery, 2)

    assert @delivery.still_attempting?, "Delivery should still be attempting"
    assert_not @delivery.failed?, "Delivery should not be failed"

    endpoint_mock = Minitest::Mock.new

    # We don't expect deactivation_processing to be called
    @delivery.stub(:endpoint, endpoint_mock) do
      assert_enqueued_jobs 1, only: Webhooks::Outgoing::DeliveryJob do
        @delivery.deliver_async
      end
    end

    endpoint_mock.verify
  end
end
