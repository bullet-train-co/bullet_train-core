require "test_helper"
require "minitest/mock"

def deactivate_subject(config = {})
  instance = Webhooks::Outgoing::EndpointHealth.new
  instance.define_singleton_method(:config) { config }
  instance.deactivate_failed_endpoints!
end

def mark_to_deactivate_subject(config = {})
  instance = Webhooks::Outgoing::EndpointHealth.new
  instance.define_singleton_method(:config) { config }
  instance.mark_to_deactivate!
end

def default_enabled_config
  {
    automatic_deactivation_endpoint_enabled: true,
    automatic_deactivation_endpoint_settings: {
      max_limit: 50,
      deactivation_in: 1.day,
    }
  }
end

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
    event_type_ids: options[:event_type_ids] || ["fake-thing.create"]
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

def create_list_of_deliveries(count, options = {})
  deliveries = []
  count.times do
    deliveries << create_delivery(options)
  end
  deliveries
end

class Webhooks::Outgoing::EndpointHealthTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @team = Team.create!(name: "test-team")
  end

  test "#deactivate_failed_endpoints! returns nil when the feature is disabled" do
    config = {automatic_deactivation_endpoint_enabled: false}
    assert_nil deactivate_subject(config)
  end

  test "#deactivate_failed_endpoints! do not deactivate endpoints when the feature is enabled and no endpoints are exists" do
    assert_equal [], deactivate_subject(default_enabled_config)
  end

  test "#deactivate_failed_endpoints! do not deactivate endpoints when all endpoints are healthy" do
    user = create_user
    endpoint = create_endpoint
    event = create_event(subject: user)
    create_delivery(endpoint: endpoint, event: event, delivered_at: Time.current - 5.minutes, created_at: Time.current - 5.minutes)
    create_delivery(endpoint: endpoint, event: event, delivered_at: Time.current, created_at: Time.current)

    assert_equal [], deactivate_subject(default_enabled_config)
  end

  test "#deactivate_failed_endpoints! deactivates endpoints when all deliveries are failed" do
    user = create_user
    endpoint = create_endpoint
    event = create_event(subject: user)
    create_delivery(endpoint: endpoint, event: event, created_at: Time.current - 8.days)
    create_list_of_deliveries(49, endpoint: endpoint, event: event)

    assert_equal [endpoint.id], deactivate_subject(default_enabled_config)
  end

  test "#mark_to_deactivate! deactivates endpoints when all deliveries are failed" do
    user = create_user
    endpoint = create_endpoint
    event = create_event(subject: user)
    create_delivery(endpoint: endpoint, event: event, created_at: Time.current - 8.days)
    create_list_of_deliveries(49, endpoint: endpoint, event: event)

    assert_equal [endpoint.id], mark_to_deactivate_subject(default_enabled_config)
  end
end
