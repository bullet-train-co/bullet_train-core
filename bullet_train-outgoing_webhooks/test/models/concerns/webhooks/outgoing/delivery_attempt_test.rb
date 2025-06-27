require "test_helper"

class Webhooks::Outgoing::DeliveryAttemptTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @team = Team.create!(name: "test-team")
    @endpoint = Webhooks::Outgoing::Endpoint.create!(url: "https://example.com/webhook", name: "test", team: @team)
    @subject = @team
    @event = Webhooks::Outgoing::Event.create!(team: @team, subject: @subject, api_version: "1")
    @event.update!(payload: {test: "data"})
  end

  test "#attempt when event is not ready" do
    # We need to bypass the validation to create a delivery without an event
    delivery = Webhooks::Outgoing::Delivery.new(endpoint: @endpoint, event: nil, endpoint_url: @endpoint.url)
    delivery.save(validate: false)
    delivery_attempt = Webhooks::Outgoing::DeliveryAttempt.new(delivery: delivery)

    result = delivery_attempt.attempt

    assert_equal false, result
    assert_equal 0, delivery_attempt.response_code
    assert_equal "Event is not ready for delivery yet", delivery_attempt.error_message
    assert delivery_attempt.persisted?
  end

  test "#attempt with successful response" do
    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: @endpoint, event: @event, endpoint_url: @endpoint.url)
    delivery_attempt = Webhooks::Outgoing::DeliveryAttempt.new(delivery: delivery)

    stub_request(:post, "https://example.com/webhook")
      .with(
        headers: {"Content-Type" => "application/json", "Host" => "example.com"},
        body: @event.payload.to_json
      )
      .to_return(status: 200, body: "OK", headers: {})

    result = delivery_attempt.attempt

    assert_equal true, result
    assert_equal 200, delivery_attempt.response_code.to_i
    assert_equal "", delivery_attempt.response_message
    assert_equal "OK", delivery_attempt.response_body
    assert_nil delivery_attempt.error_message
    assert delivery_attempt.persisted?
  end

  test "#attempt with various successful response codes" do
    [200, 201, 202, 203, 204, 205, 206, 207, 226].each do |code|
      delivery = Webhooks::Outgoing::Delivery.create!(endpoint: @endpoint, event: @event, endpoint_url: @endpoint.url)
      delivery_attempt = Webhooks::Outgoing::DeliveryAttempt.new(delivery: delivery)

      stub_request(:post, "https://example.com/webhook")
        .to_return(status: code, body: "Response", headers: {})

      result = delivery_attempt.attempt

      assert_equal true, result
      assert_equal code, delivery_attempt.response_code.to_i
      assert delivery_attempt.successful?
    end
  end

  test "#attempt with failed response" do
    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: @endpoint, event: @event, endpoint_url: @endpoint.url)
    delivery_attempt = Webhooks::Outgoing::DeliveryAttempt.new(delivery: delivery)

    stub_request(:post, "https://example.com/webhook")
      .to_return(status: 404, body: "Not Found", headers: {})

    result = delivery_attempt.attempt

    assert_equal false, result
    assert_equal 404, delivery_attempt.response_code.to_i
    assert_equal "", delivery_attempt.response_message
    assert_equal "Not Found", delivery_attempt.response_body
    assert_nil delivery_attempt.error_message
    assert delivery_attempt.persisted?
  end

  test "#attempt with network error" do
    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: @endpoint, event: @event, endpoint_url: @endpoint.url)
    delivery_attempt = Webhooks::Outgoing::DeliveryAttempt.new(delivery: delivery)

    stub_request(:post, "https://example.com/webhook")
      .to_raise(StandardError.new("Connection refused"))

    result = delivery_attempt.attempt

    assert_equal false, result
    assert_equal 0, delivery_attempt.response_code
    assert_equal "Connection refused", delivery_attempt.error_message
    assert_nil delivery_attempt.response_message
    assert_nil delivery_attempt.response_body
    assert delivery_attempt.persisted?
  end

  test "#attempt with timeout error" do
    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: @endpoint, event: @event, endpoint_url: @endpoint.url)
    delivery_attempt = Webhooks::Outgoing::DeliveryAttempt.new(delivery: delivery)

    stub_request(:post, "https://example.com/webhook")
      .to_timeout

    result = delivery_attempt.attempt

    assert_equal false, result
    assert_equal 0, delivery_attempt.response_code
    # WebMock's timeout error returns "execution expired"
    assert_match(/execution expired/i, delivery_attempt.error_message)
    assert delivery_attempt.persisted?
  end

  test "#attempt with URL without path" do
    endpoint = Webhooks::Outgoing::Endpoint.create!(url: "https://example.com", name: "no-path", team: @team)
    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: endpoint, event: @event, endpoint_url: endpoint.url)
    delivery_attempt = Webhooks::Outgoing::DeliveryAttempt.new(delivery: delivery)

    stub_request(:post, "https://example.com/")
      .with(
        headers: {"Content-Type" => "application/json", "Host" => "example.com"},
        body: @event.payload.to_json
      )
      .to_return(status: 200, body: "OK", headers: {})

    result = delivery_attempt.attempt

    assert_equal true, result
    assert_equal 200, delivery_attempt.response_code.to_i
  end

  test "#attempt with HTTPS URL" do
    endpoint = Webhooks::Outgoing::Endpoint.create!(url: "https://secure.example.com/webhook", name: "https", team: @team)
    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: endpoint, event: @event, endpoint_url: endpoint.url)
    delivery_attempt = Webhooks::Outgoing::DeliveryAttempt.new(delivery: delivery)

    stub_request(:post, "https://secure.example.com/webhook")
      .to_return(status: 200, body: "OK", headers: {})

    result = delivery_attempt.attempt

    assert_equal true, result
    assert_equal 200, delivery_attempt.response_code.to_i
  end

  test "#attempt with HTTP URL" do
    endpoint = Webhooks::Outgoing::Endpoint.create!(url: "http://example.com/webhook", name: "http", team: @team)
    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: endpoint, event: @event, endpoint_url: endpoint.url)
    delivery_attempt = Webhooks::Outgoing::DeliveryAttempt.new(delivery: delivery)

    stub_request(:post, "http://example.com/webhook")
      .to_return(status: 200, body: "OK", headers: {})

    result = delivery_attempt.attempt

    assert_equal true, result
    assert_equal 200, delivery_attempt.response_code.to_i
  end

  test "#attempt with disallowed URI when advanced hostname security is enabled" do
    original_value = BulletTrain::OutgoingWebhooks.advanced_hostname_security
    BulletTrain::OutgoingWebhooks.advanced_hostname_security = true

    endpoint = Webhooks::Outgoing::Endpoint.create!(url: "http://localhost/webhook", name: "localhost", team: @team)
    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: endpoint, event: @event, endpoint_url: endpoint.url)
    delivery_attempt = Webhooks::Outgoing::DeliveryAttempt.new(delivery: delivery)

    # Override the allowed_uri? method for this specific instance
    def delivery_attempt.allowed_uri?(uri)
      false
    end

    result = delivery_attempt.attempt

    assert_equal false, result
    assert_equal 0, delivery_attempt.response_code
    assert_match(/URI is not allowed/, delivery_attempt.error_message)
    assert delivery_attempt.persisted?
  ensure
    BulletTrain::OutgoingWebhooks.advanced_hostname_security = original_value
  end

  test "#attempt with custom verify mode" do
    original_verify_mode = BulletTrain::OutgoingWebhooks.http_verify_mode
    BulletTrain::OutgoingWebhooks.http_verify_mode = OpenSSL::SSL::VERIFY_NONE

    endpoint = Webhooks::Outgoing::Endpoint.create!(url: "https://example.com/webhook", name: "custom-verify", team: @team)
    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: endpoint, event: @event, endpoint_url: endpoint.url)
    delivery_attempt = Webhooks::Outgoing::DeliveryAttempt.new(delivery: delivery)

    stub_request(:post, "https://example.com/webhook")
      .to_return(status: 200, body: "OK", headers: {})

    result = delivery_attempt.attempt

    assert_equal true, result
    assert_equal 200, delivery_attempt.response_code.to_i
  ensure
    BulletTrain::OutgoingWebhooks.http_verify_mode = original_verify_mode
  end

  test "#still_attempting? returns true when no response code or error" do
    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: @endpoint, event: @event, endpoint_url: @endpoint.url)
    delivery_attempt = Webhooks::Outgoing::DeliveryAttempt.new(delivery: delivery)

    assert delivery_attempt.still_attempting?
  end

  test "#still_attempting? returns false when response code is set" do
    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: @endpoint, event: @event, endpoint_url: @endpoint.url)
    delivery_attempt = Webhooks::Outgoing::DeliveryAttempt.new(delivery: delivery, response_code: 200)

    assert_not delivery_attempt.still_attempting?
  end

  test "#still_attempting? returns false when error message is set" do
    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: @endpoint, event: @event, endpoint_url: @endpoint.url)
    delivery_attempt = Webhooks::Outgoing::DeliveryAttempt.new(delivery: delivery, error_message: "Error")

    assert_not delivery_attempt.still_attempting?
  end

  test "#successful? returns true for success response codes" do
    [200, 201, 202, 203, 204, 205, 206, 207, 226].each do |code|
      delivery = Webhooks::Outgoing::Delivery.create!(endpoint: @endpoint, event: @event, endpoint_url: @endpoint.url)
      delivery_attempt = Webhooks::Outgoing::DeliveryAttempt.new(delivery: delivery, response_code: code)

      assert delivery_attempt.successful?, "Expected response code #{code} to be successful"
    end
  end

  test "#successful? returns false for non-success response codes" do
    [400, 404, 500, 503].each do |code|
      delivery = Webhooks::Outgoing::Delivery.create!(endpoint: @endpoint, event: @event, endpoint_url: @endpoint.url)
      delivery_attempt = Webhooks::Outgoing::DeliveryAttempt.new(delivery: delivery, response_code: code)

      assert_not delivery_attempt.successful?, "Expected response code #{code} to not be successful"
    end
  end

  test "#failed? returns true for non-success response codes" do
    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: @endpoint, event: @event, endpoint_url: @endpoint.url)
    delivery_attempt = Webhooks::Outgoing::DeliveryAttempt.new(delivery: delivery, response_code: 404)

    assert delivery_attempt.failed?
  end

  test "#failed? returns false when still attempting" do
    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: @endpoint, event: @event, endpoint_url: @endpoint.url)
    delivery_attempt = Webhooks::Outgoing::DeliveryAttempt.new(delivery: delivery)

    assert_not delivery_attempt.failed?
  end

  test "#failed? returns false when successful" do
    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: @endpoint, event: @event, endpoint_url: @endpoint.url)
    delivery_attempt = Webhooks::Outgoing::DeliveryAttempt.new(delivery: delivery, response_code: 200)

    assert_not delivery_attempt.failed?
  end

  test "#label_string returns ordinal attempt number" do
    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: @endpoint, event: @event, endpoint_url: @endpoint.url)
    delivery_attempt = Webhooks::Outgoing::DeliveryAttempt.new(delivery: delivery, attempt_number: 1)

    assert_equal "1st Attempt", delivery_attempt.label_string

    delivery_attempt.attempt_number = 2
    assert_equal "2nd Attempt", delivery_attempt.label_string

    delivery_attempt.attempt_number = 3
    assert_equal "3rd Attempt", delivery_attempt.label_string
  end

  test "after_initialize sets attempt_number based on delivery attempt count" do
    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: @endpoint, event: @event, endpoint_url: @endpoint.url)

    # Create first attempt
    delivery_attempt1 = Webhooks::Outgoing::DeliveryAttempt.new(delivery: delivery)
    assert_equal 1, delivery_attempt1.attempt_number
    delivery_attempt1.response_code = 500
    delivery_attempt1.save!

    # Create second attempt
    delivery.reload
    delivery_attempt2 = Webhooks::Outgoing::DeliveryAttempt.new(delivery: delivery)
    assert_equal 2, delivery_attempt2.attempt_number
  end
end
