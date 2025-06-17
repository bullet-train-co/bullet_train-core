require "test_helper"
require "minitest/mock"

class Webhooks::Outgoing::EndpointDeactivatableTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include CreateWebhooksTestHelpers

  def set_config(config)
    BulletTrain::OutgoingWebhooks::Engine.config.define_singleton_method(:outgoing_webhooks) { config }
  end

  def test_enabled_config
    {
      automatic_endpoint_deactivation_enabled: true,
      automatic_endpoint_deactivation_settings: {
        max_limit: 5, # lowered for testing
        deactivation_in: 3.days,
      }
    }
  end

  def test_disabled_config
    {automatic_endpoint_deactivation_enabled: false}
  end

  setup do
    @team = Team.create!(name: "test-team")
  end

  test "#deactivation_processing does nothing when feature is disabled" do
    set_config(test_disabled_config)
    endpoint = create_endpoint

    endpoint.stub(:deactivate!, -> { raise "deactivate! should not be called" }) do
      endpoint.stub(:mark_for_deactivation!, -> { raise "mark_for_deactivation! should not be called" }) do
        assert_nil endpoint.deactivation_processing
      end
    end
  end

  test "#deactivation_processing does nothing when endpoint is already deactivated" do
    set_config(test_enabled_config)
    endpoint = create_endpoint(deactivated_at: 1.hour.ago)

    assert endpoint.deactivated?

    endpoint.stub(:deactivate!, -> { raise "deactivate! should not be called" }) do
      endpoint.stub(:mark_for_deactivation!, -> { raise "mark_for_deactivation! should not be called" }) do
        endpoint.stub(:increment!, -> { raise "increment! should not be called" }) do
          assert_nil endpoint.deactivation_processing
        end
      end
    end
  end

  test "#deactivation_processing deactivates endpoint when deactivation_in period has passed" do
    set_config(test_enabled_config)
    endpoint = create_endpoint(deactivation_limit_reached_at: 4.days.ago)

    assert endpoint.should_be_deactivated?
    assert_not endpoint.deactivated?
    assert_equal 0, endpoint.consecutive_failed_deliveries

    notify_deactivated_called = false
    endpoint.stub(:notify_deactivated, -> { notify_deactivated_called = true }) do
      assert_changes -> { endpoint.deactivated_at }, from: nil, to: ->(v) { v.present? } do
        assert_changes -> { endpoint.consecutive_failed_deliveries }, from: 0, to: 1 do
          endpoint.deactivation_processing
        end
      end
    end

    assert endpoint.deactivated?
    assert notify_deactivated_called, "notify_deactivated should be called when endpoint is deactivated"
    assert_equal 1, endpoint.consecutive_failed_deliveries
  end

  test "#deactivation_processing marks for deactivation when created enough failed deliveries" do
    set_config(test_enabled_config)
    endpoint = create_endpoint(consecutive_failed_deliveries: 4)

    assert_not endpoint.marked_for_deactivation?

    notify_deactivation_limit_reached_called = false
    endpoint.stub(:notify_deactivation_limit_reached, -> { notify_deactivation_limit_reached_called = true }) do
      assert_changes -> { endpoint.deactivation_limit_reached_at }, from: nil, to: ->(v) { v.present? } do
        assert_changes -> { endpoint.consecutive_failed_deliveries }, from: 4, to: 5 do
          endpoint.deactivation_processing
        end
      end
    end

    assert endpoint.marked_for_deactivation?
    assert notify_deactivation_limit_reached_called, "notify_deactivation_limit_reached should be called when endpoint is marked for deactivation"
  end
end
