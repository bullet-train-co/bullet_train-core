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

  test "#handle_exhausted_delivery_attempts does nothing when feature is disabled" do
    set_config(test_disabled_config)
    endpoint = create_endpoint

    endpoint.stub(:deactivate!, -> { raise "deactivate! should not be called" }) do
      endpoint.stub(:mark_for_deactivation!, -> { raise "mark_for_deactivation! should not be called" }) do
        assert_nil endpoint.handle_exhausted_delivery_attempts
      end
    end
  end

  test "#handle_exhausted_delivery_attempts does nothing when endpoint is already deactivated" do
    set_config(test_enabled_config)
    endpoint = create_endpoint(deactivated_at: 1.hour.ago)

    assert endpoint.deactivated?

    endpoint.stub(:deactivate!, -> { raise "deactivate! should not be called" }) do
      endpoint.stub(:mark_for_deactivation!, -> { raise "mark_for_deactivation! should not be called" }) do
        endpoint.stub(:increment!, -> { raise "increment! should not be called" }) do
          assert_nil endpoint.handle_exhausted_delivery_attempts
        end
      end
    end
  end

  test "#handle_exhausted_delivery_attempts deactivates endpoint when deactivation_in period has passed" do
    set_config(test_enabled_config)
    endpoint = create_endpoint(deactivation_limit_reached_at: 4.days.ago)

    assert endpoint.should_be_deactivated?
    assert_not endpoint.deactivated?
    assert_equal 0, endpoint.consecutive_failed_deliveries

    notify_deactivated_called = false
    endpoint.stub(:notify_deactivated, -> { notify_deactivated_called = true }) do
      assert_changes -> { endpoint.deactivated_at }, from: nil, to: ->(v) { v.present? } do
        assert_changes -> { endpoint.consecutive_failed_deliveries }, from: 0, to: 1 do
          endpoint.handle_exhausted_delivery_attempts
        end
      end
    end

    assert endpoint.deactivated?
    assert notify_deactivated_called, "notify_deactivated should be called when endpoint is deactivated"
    assert_equal 1, endpoint.consecutive_failed_deliveries
  end

  test "#handle_exhausted_delivery_attempts marks for deactivation when created enough failed deliveries" do
    set_config(test_enabled_config)
    endpoint = create_endpoint(consecutive_failed_deliveries: 4)

    assert_not endpoint.marked_for_deactivation?

    notify_deactivation_limit_reached_called = false
    endpoint.stub(:notify_deactivation_limit_reached, -> { notify_deactivation_limit_reached_called = true }) do
      assert_changes -> { endpoint.deactivation_limit_reached_at }, from: nil, to: ->(v) { v.present? } do
        assert_changes -> { endpoint.consecutive_failed_deliveries }, from: 4, to: 5 do
          endpoint.handle_exhausted_delivery_attempts
        end
      end
    end

    assert endpoint.marked_for_deactivation?
    assert notify_deactivation_limit_reached_called, "notify_deactivation_limit_reached should be called when endpoint is marked for deactivation"
  end

  test "#handle_exhausted_delivery_attempts does nothing when neither deactivation condition is met" do
    set_config(test_enabled_config)
    endpoint = create_endpoint

    assert_not endpoint.should_be_deactivated?
    assert_not endpoint.should_be_marked_for_deactivation?

    assert_no_changes -> { endpoint.deactivated_at } do
      assert_no_changes -> { endpoint.deactivation_limit_reached_at } do
        assert_changes -> { endpoint.consecutive_failed_deliveries }, from: 0, to: 1 do
          endpoint.handle_exhausted_delivery_attempts
        end
      end
    end
  end

  test "#should_be_deactivated? returns false when deactivation_limit_reached_at is nil" do
    set_config(test_enabled_config)
    endpoint = create_endpoint

    assert_nil endpoint.deactivation_limit_reached_at
    assert_not endpoint.should_be_deactivated?
  end

  test "#should_be_deactivated? returns false when already deactivated" do
    set_config(test_enabled_config)
    endpoint = create_endpoint(
      deactivation_limit_reached_at: 2.days.ago,
      deactivated_at: 1.hour.ago
    )

    assert endpoint.deactivated?
    assert_not endpoint.should_be_deactivated?
  end

  test "#should_be_deactivated? returns false when deactivation_in period has not passed" do
    set_config(test_enabled_config)
    endpoint = create_endpoint(deactivation_limit_reached_at: 5.minutes.ago)

    assert_not endpoint.should_be_deactivated?
  end

  test "#should_be_deactivated? returns true when deactivation_in period has passed" do
    set_config(test_enabled_config)
    endpoint = create_endpoint(deactivation_limit_reached_at: 4.days.ago)

    assert endpoint.should_be_deactivated?
  end

  test "#should_be_marked_for_deactivation? returns false when endpoint is deactivated" do
    set_config(test_enabled_config)
    endpoint = create_endpoint(deactivated_at: 1.hour.ago)

    assert endpoint.deactivated?
    assert_not endpoint.should_be_marked_for_deactivation?
  end

  test "#should_be_marked_for_deactivation? returns false when already marked for deactivation" do
    set_config(test_enabled_config)
    endpoint = create_endpoint(deactivation_limit_reached_at: 1.hour.ago)

    assert endpoint.marked_for_deactivation?
    assert_not endpoint.should_be_marked_for_deactivation?
  end

  test "#should_be_marked_for_deactivation? returns false when consecutive_failed_deliveries is below threshold" do
    set_config(test_enabled_config)
    endpoint = create_endpoint(consecutive_failed_deliveries: 4)

    assert_not endpoint.should_be_marked_for_deactivation?
  end

  test "#should_be_marked_for_deactivation? returns true when consecutive_failed_deliveries meets threshold" do
    set_config(test_enabled_config)
    endpoint = create_endpoint(consecutive_failed_deliveries: 5)

    assert endpoint.should_be_marked_for_deactivation?
  end

  test "#should_be_marked_for_deactivation? returns true when consecutive_failed_deliveries much more than threshold" do
    set_config(test_enabled_config)
    endpoint = create_endpoint(consecutive_failed_deliveries: 100)

    assert endpoint.should_be_marked_for_deactivation?
  end

  test "#mark_for_deactivation! sets deactivation_limit_reached_at" do
    endpoint = create_endpoint(deactivation_limit_reached_at: nil)

    freeze_time do
      assert_changes -> { endpoint.deactivation_limit_reached_at }, from: nil, to: Time.current do
        endpoint.mark_for_deactivation!
      end
    end
  end

  test "#mark_for_deactivation! does nothing when already marked for deactivation" do
    endpoint = create_endpoint(deactivation_limit_reached_at: 1.hour.ago)

    assert endpoint.marked_for_deactivation?

    assert_no_changes -> { endpoint.deactivation_limit_reached_at } do
      endpoint.mark_for_deactivation!
    end
  end

  test "#mark_for_deactivation! does nothing when already deactivated" do
    endpoint = create_endpoint(deactivated_at: 1.hour.ago)

    assert endpoint.deactivated?

    assert_no_changes -> { endpoint.deactivation_limit_reached_at } do
      endpoint.mark_for_deactivation!
    end
  end

  test "#deactivate! sets deactivated_at" do
    endpoint = create_endpoint(deactivated_at: nil)

    freeze_time do
      assert_changes -> { endpoint.deactivated_at }, from: nil, to: Time.current do
        endpoint.deactivate!
      end
    end
  end

  test "#deactivate! does nothing when already deactivated" do
    endpoint = create_endpoint(deactivated_at: 1.hour.ago)

    assert endpoint.deactivated?

    assert_no_changes -> { endpoint.deactivated_at } do
      endpoint.deactivate!
    end
  end

  # Integration tests combining multiple methods
  test "full deactivation workflow: mark then deactivate" do
    set_config(test_enabled_config)
    endpoint = create_endpoint(consecutive_failed_deliveries: 3)

    # Step 1: Not enough failed deliveries to mark for deactivation so just increment the counter
    assert_changes -> { endpoint.consecutive_failed_deliveries }, from: 3, to: 4 do
      endpoint.handle_exhausted_delivery_attempts
    end

    # Step 2: Now handle_exhausted_delivery_attempts should mark for deactivation
    notify_deactivation_limit_reached_called = false
    endpoint.stub(:notify_deactivation_limit_reached, -> { notify_deactivation_limit_reached_called = true }) do
      assert_changes -> { endpoint.deactivation_limit_reached_at }, from: nil, to: ->(v) { v.present? } do
        assert_changes -> { endpoint.consecutive_failed_deliveries }, from: 4, to: 5 do
          endpoint.handle_exhausted_delivery_attempts
        end
      end
    end
    assert notify_deactivation_limit_reached_called, "notify_deactivation_limit_reached should be called when marking for deactivation"

    # Step 3: Move time forward past deactivation_in period
    travel 4.days do
      # Step 4: Second handle_exhausted_delivery_attempts should deactivate
      notify_deactivated_called = false
      endpoint.stub(:notify_deactivated, -> { notify_deactivated_called = true }) do
        assert_changes -> { endpoint.deactivated_at }, from: nil, to: ->(v) { v.present? } do
          assert_changes -> { endpoint.consecutive_failed_deliveries }, from: 5, to: 6 do
            endpoint.handle_exhausted_delivery_attempts
          end
        end
      end

      assert endpoint.deactivated?
      assert notify_deactivated_called, "notify_deactivated should be called when endpoint is deactivated"
    end
  end

  test "endpoint recovery: successful delivery clears marking and consecutive_failed_deliveries" do
    endpoint = create_endpoint(deactivation_limit_reached_at: 1.hour.ago, consecutive_failed_deliveries: 5)
    delivery = create_delivery(endpoint: endpoint, delivered_at: nil)

    assert_changes -> { endpoint.deactivation_limit_reached_at }, from: ->(v) { v.present? }, to: nil do
      assert_changes -> { endpoint.consecutive_failed_deliveries }, from: 5, to: 0 do
        delivery.update!(delivered_at: Time.current)
      end
    end
  end
end
