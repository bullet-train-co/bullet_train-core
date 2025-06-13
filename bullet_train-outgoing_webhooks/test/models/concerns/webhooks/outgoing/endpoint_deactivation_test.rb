require "test_helper"
require "minitest/mock"

class Webhooks::Outgoing::EndpointDeactivationTest < ActiveSupport::TestCase
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
        assert_nil endpoint.deactivation_processing
      end
    end
  end

  test "#deactivation_processing deactivates endpoint when deactivation_in period has passed" do
    set_config(test_enabled_config)
    endpoint = create_endpoint(deactivation_limit_reached_at: 4.days.ago)

    assert endpoint.should_be_deactivated?
    assert_not endpoint.deactivated?

    notify_deactivated_called = false
    endpoint.stub(:notify_deactivated, -> { notify_deactivated_called = true }) do
      assert_changes -> { endpoint.deactivated_at }, from: nil, to: ->(v) { v.present? } do
        endpoint.deactivation_processing
      end
    end

    assert endpoint.deactivated?
    assert notify_deactivated_called, "notify_deactivated should be called when endpoint is deactivated"
  end

  test "#deactivation_processing marks for deactivation when created enough failed deliveries" do
    set_config(test_enabled_config)
    endpoint = create_endpoint
    event = create_event
    # Create failed deliveries that should trigger marking for deactivation
    create_list_of_deliveries(5, endpoint: endpoint, event: event, created_at: created_at_that_considered_failed)

    assert endpoint.should_be_marked_for_deactivation?
    assert_not endpoint.marked_for_deactivation?

    notify_deactivation_limit_reached_called = false
    endpoint.stub(:notify_deactivation_limit_reached, -> { notify_deactivation_limit_reached_called = true }) do
      assert_changes -> { endpoint.deactivation_limit_reached_at }, from: nil, to: ->(v) { v.present? } do
        endpoint.deactivation_processing
      end
    end

    assert endpoint.marked_for_deactivation?
    assert notify_deactivation_limit_reached_called, "notify_deactivation_limit_reached should be called when endpoint is marked for deactivation"
  end

  test "#deactivation_processing does nothing when neither deactivation condition is met" do
    set_config(test_enabled_config)
    endpoint = create_endpoint

    assert_not endpoint.should_be_deactivated?
    assert_not endpoint.should_be_marked_for_deactivation?

    assert_no_changes -> { endpoint.deactivated_at } do
      assert_no_changes -> { endpoint.deactivation_limit_reached_at } do
        endpoint.deactivation_processing
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

  # Tests for should_be_marked_for_deactivation? method
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

  test "#should_be_marked_for_deactivation? returns false when there are recent successful deliveries" do
    set_config(test_enabled_config)
    user = create_user
    event = create_event(subject: user)
    endpoint = create_endpoint

    # Create failed deliveries beyond max_attempts_period
    create_list_of_deliveries(5, endpoint: endpoint, event: event, created_at: created_at_that_considered_failed)

    # Create a recent successful delivery
    create_delivery(endpoint: endpoint, event: event, delivered_at: 5.minutes.ago, created_at: 5.minutes.ago)

    assert_not endpoint.should_be_marked_for_deactivation?
  end

  test "#should_be_marked_for_deactivation? returns true when there are old successful deliveries" do
    set_config(test_enabled_config)
    event = create_event
    endpoint = create_endpoint

    # Create an old successful delivery (more than max_attempts_period + 1.hour ago)
    old_success_time = (Webhooks::Outgoing::Delivery.max_attempts_period + 2.hours).ago
    create_delivery(endpoint: endpoint, event: event, delivered_at: old_success_time, created_at: old_success_time)

    # Create failed deliveries that should trigger marking
    create_list_of_deliveries(5, endpoint: endpoint, event: event, created_at: created_at_that_considered_failed)

    assert endpoint.should_be_marked_for_deactivation?
  end

  test "#should_be_marked_for_deactivation? returns true when there are enough old failed deliveries" do
    set_config(test_enabled_config)
    event = create_event
    endpoint = create_endpoint

    # Create failed deliveries beyond max_attempts_period that exceed max_limit
    create_list_of_deliveries(5, endpoint: endpoint, event: event, created_at: created_at_that_considered_failed)

    assert endpoint.should_be_marked_for_deactivation?
  end

  test "#should_be_marked_for_deactivation? returns false when failed deliveries are fewer than max_limit" do
    set_config(test_enabled_config)
    event = create_event
    endpoint = create_endpoint

    # Create failed deliveries fewer than max_limit (5)
    create_list_of_deliveries(4, endpoint: endpoint, event: event, created_at: created_at_that_considered_failed)

    assert_not endpoint.should_be_marked_for_deactivation?
  end

  test "#should_be_marked_for_deactivation? returns false when failed deliveries are within max_attempts_period" do
    set_config(test_enabled_config)
    user = create_user
    event = create_event(subject: user)
    endpoint = create_endpoint

    # Create failed deliveries within max_attempts_period
    create_list_of_deliveries(5, endpoint: endpoint, event: event, created_at: 30.minutes.ago)

    assert_not endpoint.should_be_marked_for_deactivation?
  end

  test "#should_be_marked_for_deactivation? handles mixed scenario correctly" do
    set_config(test_enabled_config)
    event = create_event
    endpoint = create_endpoint

    # Create old failed deliveries (should count)
    create_list_of_deliveries(4, endpoint: endpoint, event: event, created_at: created_at_that_considered_failed)

    # Create recent failed deliveries (should not count)
    create_list_of_deliveries(2, endpoint: endpoint, event: event, created_at: 30.minutes.ago)

    # Only 4 old deliveries should count, which is less than max_limit (5)
    assert_not endpoint.should_be_marked_for_deactivation?
  end

  test "#should_be_marked_for_deactivation? ignores recent deliveries when counting old ones" do
    set_config(test_enabled_config)
    event = create_event
    endpoint = create_endpoint

    # Create old failed deliveries that exceed max_limit
    create_list_of_deliveries(5, endpoint: endpoint, event: event, created_at: created_at_that_considered_failed)

    # Create recent failed deliveries (should not affect the count)
    create_list_of_deliveries(3, endpoint: endpoint, event: event, created_at: 30.minutes.ago)

    # The 5 old deliveries should trigger marking
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
    user = create_user
    event = create_event(subject: user)
    endpoint = create_endpoint

    # Step 1: Create conditions for marking
    create_list_of_deliveries(6, endpoint: endpoint, event: event, created_at: created_at_that_considered_failed)

    # Step 2: First deactivation_processing should mark for deactivation
    notify_deactivation_limit_reached_called = false
    endpoint.stub(:notify_deactivation_limit_reached, -> { notify_deactivation_limit_reached_called = true }) do
      assert_changes -> { endpoint.deactivation_limit_reached_at }, from: nil, to: ->(v) { v.present? } do
        endpoint.deactivation_processing
      end
    end
    assert notify_deactivation_limit_reached_called, "notify_deactivation_limit_reached should be called when marking for deactivation"

    # Step 3: Move time forward past deactivation_in period
    travel 4.days do
      # Step 4: Second deactivation_processing should deactivate
      notify_deactivated_called = false
      endpoint.stub(:notify_deactivated, -> { notify_deactivated_called = true }) do
        assert_changes -> { endpoint.deactivated_at }, from: nil, to: ->(v) { v.present? } do
          endpoint.deactivation_processing
        end
      end

      assert endpoint.deactivated?
      assert notify_deactivated_called, "notify_deactivated should be called when endpoint is deactivated"
    end
  end

  test "endpoint recovery: successful delivery clears marking" do
    BulletTrain::OutgoingWebhooks::Engine.config.stub(:outgoing_webhooks, test_enabled_config) do
      user = create_user
      event = create_event(subject: user)
      endpoint = create_endpoint(deactivation_limit_reached_at: 1.hour.ago)

      # Create delivery without delivered_at initially
      delivery = create_delivery(endpoint: endpoint, event: event, delivered_at: nil)

      # This should clear the deactivation limit reached timestamp when we mark it as delivered
      assert_changes -> { endpoint.deactivation_limit_reached_at }, from: ->(v) { v.present? }, to: nil do
        delivery.update!(delivered_at: Time.current)
      end
    end
  end
end
