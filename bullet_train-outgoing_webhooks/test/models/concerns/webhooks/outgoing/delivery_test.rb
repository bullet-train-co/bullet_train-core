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

    assert_changes -> { delivery.delivery_attempts.count }, from: 0, to: 1 do
      delivery.deliver
    end

    assert_enqueued_jobs 1, only: Webhooks::Outgoing::DeliveryJob
  end

  test "#deliver respects deactivated endpoint even with existing delivery attempts" do
    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: @endpoint, event: @event, endpoint_url: @endpoint.url)

    delivery.delivery_attempts.create!(attempt_number: 1, response_code: 500, error_message: "Server error")

    @endpoint.update!(deactivated_at: 1.hour.ago)

    assert_no_changes -> { delivery.delivery_attempts.count } do
      delivery.deliver
    end
    assert_no_enqueued_jobs only: Webhooks::Outgoing::DeliveryJob
  end

  test "clears endpoint deactivation_limit_reached_at when delivery is marked as delivered" do
    @endpoint.update!(deactivation_limit_reached_at: 1.hour.ago)
    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: @endpoint, event: @event, endpoint_url: @endpoint.url)

    assert_changes -> { @endpoint.reload.deactivation_limit_reached_at }, from: ->(v) { v.present? }, to: nil do
      delivery.update!(delivered_at: Time.current)
    end
  end

  test "does not clear endpoint deactivation_limit_reached_at when delivery is not delivered" do
    @endpoint.update!(deactivation_limit_reached_at: 1.hour.ago)
    delivery = Webhooks::Outgoing::Delivery.create!(endpoint: @endpoint, event: @event, endpoint_url: @endpoint.url)

    assert_not_nil @endpoint.deactivation_limit_reached_at

    # Update delivery but don't mark as delivered
    delivery.update!(created_at: 1.minute.ago)

    assert_not_nil @endpoint.reload.deactivation_limit_reached_at
  end
end
