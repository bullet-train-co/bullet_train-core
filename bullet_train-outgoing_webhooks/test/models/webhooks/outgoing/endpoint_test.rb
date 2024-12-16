require "test_helper"

class Webhooks::Outgoing::EndpointTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @team = Team.create!(name: "test-team")
    @endpoint = Webhooks::Outgoing::Endpoint.create!(url: "https://example.com/webhook", name: "test", team: @team)
  end

  test "#create should accept valid event_types" do
    @endpoint = Webhooks::Outgoing::Endpoint.create!(
      url: "https://example.com/webhook",
      name: "test",
      team: @team,
      event_type_ids: [Webhooks::Outgoing::EventType.all.first]
    )
    assert @endpoint.persisted?
  end

  test "#create should accept non-existent event_types" do
    @endpoint = Webhooks::Outgoing::Endpoint.create!(
      url: "https://example.com/webhook",
      name: "test",
      team: @team,
      event_type_ids: ["fake-thing.create"]
    )
    assert @endpoint.persisted?
  end

  test "#event_types should not raise an error for non-existent event_type_ids" do
    @endpoint = Webhooks::Outgoing::Endpoint.create!(
      url: "https://example.com/webhook",
      name: "test",
      team: @team,
      event_type_ids: ["fake-thing.create"]
    )
    assert_equal [], @endpoint.event_types
  end
end
