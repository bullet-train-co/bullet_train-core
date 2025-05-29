require "test_helper"

class Webhooks::Outgoing::DeliveryAttemptTest < ActiveSupport::TestCase
  setup do
    @team = Team.create!(name: "test-team")
    @endpoint = Webhooks::Outgoing::Endpoint.create!(
      url: "https://example.com/webhook",
      name: "test",
      team: @team
    )

    @event = Webhooks::Outgoing::Event.create!(
      team: @team,
      subject: @team,
      uuid: SecureRandom.uuid,
      payload: {"test" => "data"},
      event_type_id: "team.created",
      data: {"good" => "data"},
      api_version: 1
    )

    @delivery = Webhooks::Outgoing::Delivery.create!(
      endpoint: @endpoint,
      event: @event,
      endpoint_url: "https://example.com/webhook"
    )

    @attempt = @delivery.delivery_attempts.new

    stub_request(:any, "https://example.com/webhook")
      .to_return(status: 200, body: "Success", headers: {})
  end

  test "#attempt creates a request with valid x-webhook-headers and payload" do
    @attempt.attempt

    assert_requested :post, "https://example.com/webhook", {
      headers: {
        "X-Bullet-Train-Webhook-Timestamp" => /.+/,
        "X-Bullet-Train-Webhook-Signature" => /.+/,
        "X-Bullet-Train-Webhook-Id" => @event.uuid,
        "Content-Type" => "application/json"
      },
      body: {
        "event_id" => @event.uuid,
        "event_type" => "team.created",
        "subject_id" => @team.id,
        "subject_type" => "Team",
        "data" => {
          "good" => "data"
        }
      }
    }
  end
end
