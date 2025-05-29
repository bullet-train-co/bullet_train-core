require "test_helper"

class Webhooks::Outgoing::EndpointTest < ActiveSupport::TestCase
  setup do
    @team = Team.create!(name: "test-team")
  end

  test "#event_types accepts and returns existent EventTypes" do
    valid_event_type = Webhooks::Outgoing::EventType.all.first
    endpoint = Webhooks::Outgoing::Endpoint.create!(
      url: "https://example.com/webhook",
      name: "test",
      team: @team,
      event_type_ids: [valid_event_type.id]
    )
    assert endpoint.persisted?
    assert_equal [valid_event_type.id], endpoint.event_types.map(&:id)
  end

  test "#create ignores non-existent event_types" do
    endpoint = Webhooks::Outgoing::Endpoint.create!(
      url: "https://example.com/webhook",
      name: "test",
      team: @team,
      event_type_ids: ["fake-thing.create"]
    )
    assert endpoint.persisted?
    assert_equal [], endpoint.event_types
  end

  test "#create generates webhook_secret" do
    endpoint = Webhooks::Outgoing::Endpoint.create!(
      url: "https://example.com/webhook",
      name: "test-auto-secret",
      team: @team
    )

    assert_not_nil endpoint.webhook_secret
    assert_equal 64, endpoint.webhook_secret.length
  end

  test "#rotate_webhook_secret! changes the webhook secret" do
    endpoint = Webhooks::Outgoing::Endpoint.create!(url: "https://example.com/webhook", name: "test", team: @team)

    old_secret = endpoint.webhook_secret
    endpoint.rotate_webhook_secret!

    assert_not_equal old_secret, endpoint.webhook_secret
    assert_equal 64, endpoint.webhook_secret.length
  end
end
