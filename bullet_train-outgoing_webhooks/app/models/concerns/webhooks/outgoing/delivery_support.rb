module Webhooks::Outgoing::DeliverySupport
  extend ActiveSupport::Concern

  included do
    belongs_to :endpoint, class_name: "Webhooks::Outgoing::Endpoint"
    belongs_to :event, class_name: "Webhooks::Outgoing::Event"

    has_one :team, through: :endpoint unless BulletTrain::OutgoingWebhooks.parent_class_specified?
    has_many :delivery_attempts, class_name: "Webhooks::Outgoing::DeliveryAttempt", dependent: :destroy, foreign_key: :delivery_id

    after_commit :reset_endpoint_failed_deliveries_tracking!, if: :delivered?
  end

  class_methods do
    def max_attempts_period
      ATTEMPT_SCHEDULE.values.sum
    end
  end

  ATTEMPT_SCHEDULE = {
    1 => 15.seconds,
    2 => 1.minute,
    3 => 5.minutes,
    4 => 15.minutes,
    5 => 1.hour,
    6 => 24.hours,
  }

  def label_string
    event.short_uuid
  end

  def next_reattempt_delay
    ATTEMPT_SCHEDULE[attempt_count]
  end

  def deliver_async
    if still_attempting?
      Webhooks::Outgoing::DeliveryJob.set(wait: next_reattempt_delay).perform_later(self)
    else
      # All delivery attempts have now failed, should we deactivate the endpoint?
      endpoint.deactivation_processing
    end
  end

  # This method is used to create an attempt and deliver a webhook.
  # If the endpoint is disabled, the attempt will not be created and the webhook will not be delivered.
  # You can bypass this condition by passing `force: true`
  def deliver(force: false)
    return if endpoint.deactivated? && !force
    # TODO If we ever do away with the `async: true` default for webhook generation, then I believe this needs to
    # change otherwise we'd be attempting the first delivery of webhooks inline.
    if delivery_attempts.new.attempt
      touch(:delivered_at)
    else
      deliver_async
    end
  end

  def attempt_count
    delivery_attempts.count
  end

  def delivered?
    delivered_at.present?
  end

  def still_attempting?
    return false if delivered?
    attempt_count <= max_attempts
  end

  def failed?
    !delivered? && !still_attempting?
  end

  def not_attempted?
    attempt_count.zero?
  end

  def attempts_schedule_period_elapsed?
    created_at < max_attempts_period.ago
  end

  # This method is used to display delivery statuses in the UI.
  # For deactivated endpoints, we don't make any delivery attempts, however, the delivery itself is still created,
  # so we show it as "failed" in the UI.
  # We also show deliveries as failed when the maximum attempt period has elapsed.
  def failed_or_not_attempted_or_elapsed?
    failed? || not_attempted? || attempts_schedule_period_elapsed?
  end

  def name
    event.short_uuid
  end

  def max_attempts
    ATTEMPT_SCHEDULE.keys.max
  end

  def max_attempts_period
    self.class.max_attempts_period
  end

  def reset_endpoint_failed_deliveries_tracking!
    endpoint.reset_failed_deliveries_tracking!
  end
end
