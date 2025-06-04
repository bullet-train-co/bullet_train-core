require "test_helper"
require "minitest/mock"

def mark_to_deactivate_subject(config = {})
  BulletTrain::OutgoingWebhooks::Engine.config.stub(:outgoing_webhooks, config) do
    instance = Webhooks::Outgoing::EndpointHealth.new
    instance.mark_to_deactivate!
  end
end

def deactivate_subject(config = {})
  BulletTrain::OutgoingWebhooks::Engine.config.stub(:outgoing_webhooks, config) do
    instance = Webhooks::Outgoing::EndpointHealth.new
    instance.deactivate_failed_endpoints!
  end
end

def test_enabled_config
  {
    automatic_deactivation_endpoint_enabled: true,
    automatic_deactivation_endpoint_settings: {
      max_limit: 5, # lowered for testing
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

def create_list_of_deliveries(count, options = {})
  deliveries = []
  count.times do
    deliveries << create_delivery(options)
  end
  deliveries
end

def reached_limit_endpoints
  Webhooks::Outgoing::Endpoint
    .where.not(deactivation_limit_reached_at: nil)
    .where(deactivated_at: nil)
end

def deactivated_endpoints
  Webhooks::Outgoing::Endpoint
    .where.not(deactivated_at: nil)
end

def created_at_that_considered_failed
  Webhooks::Outgoing::Delivery.max_attempts_period.ago - 1.hour
end

class Webhooks::Outgoing::EndpointHealthTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @team = Team.create!(name: "test-team")
  end

  test "#mark_to_deactivate! returns nil when the feature is disabled" do
    config = {automatic_deactivation_endpoint_enabled: false}
    assert_nil mark_to_deactivate_subject(config)
  end

  test "#mark_to_deactivate! does not mark to deactivate endpoints if the feature is enabled and there are no endpoints to deactivate" do
    assert_equal [], mark_to_deactivate_subject(test_enabled_config)
  end

  test "#mark_to_deactivate! does not mark to deactivate endpoints if all endpoints are healthy" do
    user = create_user
    endpoint = create_endpoint
    event = create_event(subject: user)
    create_delivery(endpoint: endpoint, event: event, delivered_at: Time.current - 5.minutes, created_at: Time.current - 5.minutes)
    create_delivery(endpoint: endpoint, event: event, delivered_at: Time.current, created_at: Time.current)

    assert_equal [], mark_to_deactivate_subject(test_enabled_config)
    assert reached_limit_endpoints.count.zero?
  end

  test "#mark_to_deactivate! does not mark to deactivate already deactivated endpoints" do
    user = create_user
    endpoint = create_endpoint(deactivated_at: Time.current)
    event = create_event(subject: user)
    create_list_of_deliveries(5, endpoint: endpoint, event: event)

    assert_equal [], mark_to_deactivate_subject(test_enabled_config)
    assert reached_limit_endpoints.count.zero?
  end

  test "#mark_to_deactivate! does not mark to deactivate endpoints marked as having reached the deactivation limit" do
    user = create_user
    endpoint = create_endpoint(deactivation_limit_reached_at: Time.current)
    event = create_event(subject: user)
    create_list_of_deliveries(5, endpoint: endpoint, event: event)

    assert_equal [], mark_to_deactivate_subject(test_enabled_config)
    assert [endpoint.id], reached_limit_endpoints.pluck(:id) # marked on test setup
  end

  test "#mark_to_deactivate! marks to deactivate endpoints when all deliveries fail and the count exceeds the limit" do
    user = create_user
    event = create_event(subject: user)
    endpoint_to_deactivate = create_endpoint
    create_list_of_deliveries(5, endpoint: endpoint_to_deactivate, event: event, created_at: created_at_that_considered_failed)

    good_endpoint = create_endpoint
    create_list_of_deliveries(5, endpoint: good_endpoint, event: event, delivered_at: 7.days.ago, created_at: 7.days.ago)

    assert_enqueued_with(job: Webhooks::Outgoing::EndpointNotificationJob, args: [{endpoint_id: endpoint_to_deactivate.id, notification_type: "deactivation_limit_reached"}]) do
      assert_equal [endpoint_to_deactivate.id], mark_to_deactivate_subject(test_enabled_config)
    end
    assert_equal [endpoint_to_deactivate.id], reached_limit_endpoints.pluck(:id)
  end

  test "#mark_to_deactivate! marks to deactivate endpoints when all deliveries fail and the count is less than the limit" do
    user = create_user
    event = create_event(subject: user)
    endpoint_to_deactivate = create_endpoint
    create_list_of_deliveries(4, endpoint: endpoint_to_deactivate, event: event)

    assert_equal [], mark_to_deactivate_subject(test_enabled_config)
    assert reached_limit_endpoints.count.zero?
  end

  test "#mark_to_deactivate! marks to deactivate endpoints when there is a successful delivery after a failed delivery" do
    user = create_user
    event = create_event(subject: user)
    recovered_endpoint = create_endpoint
    create_list_of_deliveries(5, endpoint: recovered_endpoint, event: event, created_at: 10.minutes.ago)
    create_delivery(endpoint: recovered_endpoint, event: event, delivered_at: 5.minutes.ago, created_at: 5.minutes.ago)

    assert_equal [], mark_to_deactivate_subject(test_enabled_config)
  end

  test "#mark_to_deactivate! marks to deactivate endpoints if there is a successful delivery before a failure" do
    user = create_user
    event = create_event(subject: user)
    endpoint_to_deactivate = create_endpoint
    create_delivery(endpoint: endpoint_to_deactivate, event: event, delivered_at: 5.minutes.ago, created_at: 5.minutes.ago)
    create_list_of_deliveries(5, endpoint: endpoint_to_deactivate, event: event, created_at: created_at_that_considered_failed)

    assert_equal [endpoint_to_deactivate.id], mark_to_deactivate_subject(test_enabled_config)
    assert_equal [endpoint_to_deactivate.id], reached_limit_endpoints.pluck(:id)
  end

  test "#mark_to_deactivate! does not mark to deactivate endpoints when failed deliveries are created within max_attempts_period" do
    user = create_user
    event = create_event(subject: user)
    endpoint = create_endpoint

    [30.minutes, 1.hour].each do |time|
      create_delivery(endpoint: endpoint, event: event, created_at: time.ago)
    end

    assert_equal [], mark_to_deactivate_subject(test_enabled_config)
    assert reached_limit_endpoints.count.zero?
  end

  test "#mark_to_deactivate! handles mixed scenario: some deliveries within max_attempts_period, some beyond" do
    user = create_user
    event = create_event(subject: user)
    endpoint_to_deactivate = create_endpoint

    create_list_of_deliveries(4, endpoint: endpoint_to_deactivate, event: event, created_at: created_at_that_considered_failed)
    create_delivery(endpoint: endpoint_to_deactivate, event: event, created_at: 30.minutes.ago)

    # Only the 4 old deliveries should count, which is less than the limit of 5
    assert_equal [], mark_to_deactivate_subject(test_enabled_config)
    assert reached_limit_endpoints.count.zero?
  end

  test "#mark_to_deactivate! marks endpoint when enough old failed deliveries exceed limit, ignoring recent ones" do
    user = create_user
    event = create_event(subject: user)
    endpoint_to_deactivate = create_endpoint

    create_list_of_deliveries(5, endpoint: endpoint_to_deactivate, event: event, created_at: created_at_that_considered_failed)
    create_list_of_deliveries(2, endpoint: endpoint_to_deactivate, event: event, created_at: 30.minutes.ago)

    assert_enqueued_with(job: Webhooks::Outgoing::EndpointNotificationJob, args: [{endpoint_id: endpoint_to_deactivate.id, notification_type: "deactivation_limit_reached"}]) do
      assert_equal [endpoint_to_deactivate.id], mark_to_deactivate_subject(test_enabled_config)
    end
    assert_equal [endpoint_to_deactivate.id], reached_limit_endpoints.pluck(:id)
  end

  test "#deactivate_failed_endpoints! returns nil if the feature is disabled" do
    config = {automatic_deactivation_endpoint_enabled: false}
    assert_nil deactivate_subject(config)
  end

  test "#deactivate_failed_endpoints! does not deactivate endpoints if the feature is enabled and there are no endpoints to deactivate" do
    assert_equal [], deactivate_subject(test_enabled_config)
  end

  test "#deactivate_failed_endpoints! does not deactivate endpoints if it was marked less than day ago and no deliveries" do
    create_endpoint(deactivation_limit_reached_at: Time.current)

    assert_equal [], deactivate_subject(test_enabled_config)
    assert deactivated_endpoints.count.zero?
  end

  test "#deactivate_failed_endpoints! does not deactivate endpoints if it was marked less than day ago and has only failed deliveries" do
    user = create_user
    event = create_event(subject: user)
    endpoint = create_endpoint(deactivation_limit_reached_at: 5.minutes.ago)
    create_delivery(endpoint: endpoint, event: event, created_at: 5.minutes.ago)
    create_delivery(endpoint: endpoint, event: event, created_at: Time.current)

    assert_equal [], deactivate_subject(test_enabled_config)
    assert deactivated_endpoints.count.zero?
  end

  test "#deactivate_failed_endpoints! does not deactivate endpoints if it was marked more than day ago and has successful deliveries after that" do
    user = create_user
    event = create_event(subject: user)
    endpoint = create_endpoint(deactivation_limit_reached_at: 2.days.ago)
    create_delivery(endpoint: endpoint, event: event, delivered_at: 2.minutes.ago, created_at: 5.minutes.ago)

    assert_equal [], deactivate_subject(test_enabled_config)
    assert deactivated_endpoints.count.zero?
  end

  test "#deactivate_failed_endpoints! deactivates endpoints if it was marked more than day ago and has only failed deliveries" do
    user = create_user
    event = create_event(subject: user)
    endpoint = create_endpoint(deactivation_limit_reached_at: 2.days.ago)
    create_delivery(endpoint: endpoint, event: event, created_at: 5.minutes.ago)

    assert_enqueued_with(job: Webhooks::Outgoing::EndpointNotificationJob, args: [{endpoint_id: endpoint.id, notification_type: "deactivated"}]) do
      assert_equal [endpoint.id], deactivate_subject(test_enabled_config)
    end
    assert_equal [endpoint.id], deactivated_endpoints.pluck(:id)
  end
end
