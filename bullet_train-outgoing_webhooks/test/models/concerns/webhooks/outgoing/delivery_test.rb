require "test_helper"

class Webhooks::Outgoing::DeliveryTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @team = Team.create!(name: "test-team")
    @endpoint = Webhooks::Outgoing::Endpoint.create!(url: "https://example.com/webhook", name: "test", team: @team)
    @subject = @team
    @event = Webhooks::Outgoing::Event.create!(team: @team, subject: @subject, api_version: "1")
  end

  test "#deliver_async schedule jobs" do
    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: @endpoint, event: @event)
    freeze_time

    # first job runs immediately
    assert_enqueued_with(job: Webhooks::Outgoing::DeliveryJob, at: nil) do
      delivery.deliver_async
    end

    # shedule other jobs with the delays from ATTEMPT_SCHEDULE
    Webhooks::Outgoing::Delivery::ATTEMPT_SCHEDULE.each do |attempt, delay|
      delivery.reload
      delivery.delivery_attempts.create!(attempt_number: attempt, response_code: 500, error_message: "error")
      assert_enqueued_with(job: Webhooks::Outgoing::DeliveryJob, at: delay.from_now) do
        delivery.deliver_async
      end
    end

    assert_equal Webhooks::Outgoing::Delivery::ATTEMPT_SCHEDULE.size, Webhooks::Outgoing::DeliveryAttempt.count, "amount of attempts should e equal to ATTEMPT_SCHEDULE"
  end

  test "#deliver does not attempt delivery when endpoint is deactivated" do
    @endpoint.update!(deactivated_at: 1.hour.ago)
    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: @endpoint, event: @event, endpoint_url: @endpoint.url)

    assert @endpoint.deactivated?
    assert_no_changes -> { delivery.delivery_attempts.count } do
      delivery.deliver
    end
    assert_nil delivery.reload.delivered_at
    assert_no_enqueued_jobs only: Webhooks::Outgoing::DeliveryJob
  end

  test "#deliver processes normally when endpoint is active" do
    assert @endpoint.active?

    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: @endpoint, event: @event, endpoint_url: @endpoint.url)

    stub_request(:post, "https://example.com/webhook").to_return(status: 200, body: "", headers: {})

    assert_changes -> { delivery.delivery_attempts.count }, from: 0, to: 1 do
      delivery.deliver
    end

    assert_not_nil delivery.reload.delivered_at, "delivery should be marked as delivered"
    assert_no_enqueued_jobs only: Webhooks::Outgoing::DeliveryJob # do not schedule an another attempt
  end

  test "#deliver does not mark as delivered when delivery attempt fails" do
    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: @endpoint, event: @event, endpoint_url: @endpoint.url)

    stub_request(:post, "https://example.com/webhook").to_return(status: 500, body: "", headers: {})

    assert_changes -> { delivery.delivery_attempts.count }, from: 0, to: 1 do
      delivery.deliver
    end

    assert_nil delivery.reload.delivered_at, "delivery should not be marked as delivered when attempt fails"
    assert_enqueued_jobs 1, only: Webhooks::Outgoing::DeliveryJob # should schedule retry
  end

  test "#deliver respects deactivated endpoint even with existing delivery attempts" do
    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: @endpoint, event: @event, endpoint_url: @endpoint.url)

    delivery.delivery_attempts.create!(attempt_number: 1, response_code: 500, error_message: "Server error")

    @endpoint.update!(deactivated_at: 1.hour.ago)

    assert_no_changes -> { delivery.delivery_attempts.count } do
      delivery.deliver
    end
    assert_nil delivery.reload.delivered_at, "delivery should not be marked as delivered"
    assert_no_enqueued_jobs only: Webhooks::Outgoing::DeliveryJob
  end

  test "does not clear endpoint deactivation_limit_reached_at when delivery is not delivered" do
    @endpoint.update!(deactivation_limit_reached_at: 1.hour.ago)
    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: @endpoint, event: @event, endpoint_url: @endpoint.url)

    assert_not_nil @endpoint.deactivation_limit_reached_at

    # Update delivery but don't mark as delivered
    delivery.update!(created_at: 1.minute.ago)

    assert_not_nil @endpoint.reload.deactivation_limit_reached_at
  end

  test "#failed_or_not_attempted_or_elapsed? returns true when delivery has failed" do
    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: @endpoint, event: @event, endpoint_url: @endpoint.url)

    max_attempts = delivery.max_attempts
    (max_attempts + 1).times do |i|
      delivery.delivery_attempts.create!(attempt_number: i + 1, response_code: 500, error_message: "Server error")
    end

    assert delivery.failed?, "Delivery should be failed"
    assert delivery.failed_or_not_attempted_or_elapsed?, "Should return true for failed delivery"
  end

  test "#failed_or_not_attempted_or_elapsed? returns true when delivery has not been attempted" do
    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: @endpoint, event: @event, endpoint_url: @endpoint.url)

    assert delivery.not_attempted?, "Delivery should not be attempted"
    assert delivery.failed_or_not_attempted_or_elapsed?, "Should return true for not attempted delivery"
  end

  test "#failed_or_not_attempted_or_elapsed? returns true when attempts schedule period has elapsed" do
    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: @endpoint, event: @event, endpoint_url: @endpoint.url)

    old_created_at = Webhooks::Outgoing::Delivery::ATTEMPT_SCHEDULE.values.sum.ago - 1.hour
    delivery.update!(created_at: old_created_at)

    assert delivery.attempts_schedule_period_elapsed?, "Schedule period should have elapsed"
    assert delivery.failed_or_not_attempted_or_elapsed?, "Should return true when schedule period elapsed"
  end

  test "#failed_or_not_attempted_or_elapsed? returns false when delivery is delivered" do
    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: @endpoint, event: @event, endpoint_url: @endpoint.url, delivered_at: Time.current)

    delivery.delivery_attempts.create!(attempt_number: 1, response_code: 200)

    assert delivery.delivered?, "Delivery should be delivered"
    refute delivery.failed_or_not_attempted_or_elapsed?, "Should return false for delivered delivery"
  end

  test "#failed_or_not_attempted_or_elapsed? returns false when delivery is still attempting" do
    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: @endpoint, event: @event, endpoint_url: @endpoint.url)

    # Create some attempts but not more than max allowed, and not delivered
    delivery.delivery_attempts.create!(attempt_number: 1, response_code: 500, error_message: "Server error")
    delivery.delivery_attempts.create!(attempt_number: 2, response_code: 500, error_message: "Server error")

    assert delivery.still_attempting?, "Delivery should still be attempting"
    refute delivery.failed_or_not_attempted_or_elapsed?, "Should return false when still attempting"
  end
end
