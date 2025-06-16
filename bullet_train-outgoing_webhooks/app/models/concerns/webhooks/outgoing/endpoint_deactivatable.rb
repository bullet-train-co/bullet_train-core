module Webhooks::Outgoing::EndpointDeactivatable
  extend ActiveSupport::Concern

  def active?
    deactivated_at.nil?
  end

  def deactivated?
    deactivated_at.present?
  end

  def marked_for_deactivation?
    deactivation_limit_reached_at.present? && deactivated_at.nil?
  end

  def clear_deactivation_limit_reached_at!
    update(deactivation_limit_reached_at: nil)
  end

  def deactivate!
    return if deactivated?

    update(deactivated_at: Time.current)
  end

  def mark_for_deactivation!
    return if marked_for_deactivation?
    return if deactivated?

    update(deactivation_limit_reached_at: Time.current)
  end

  def deactivation_processing
    return unless BulletTrain::OutgoingWebhooks::Engine.config.outgoing_webhooks[:automatic_endpoint_deactivation_enabled]
    return if deactivated?

    # If the endpoint is marked for deactivation, we check if the cooling-off period (deactivation_in setting) has passed.
    # If so, we mark it as deactivated.
    if should_be_deactivated?
      deactivate!
      notify_deactivated
    elsif should_be_marked_for_deactivation?
      mark_for_deactivation!
      notify_deactivation_limit_reached
    end
  end

  def should_be_deactivated?
    return false unless deactivation_limit_reached_at
    return false if deactivated_at

    deactivation_limit_reached_at <= BulletTrain::OutgoingWebhooks::Engine.config.outgoing_webhooks.dig(:automatic_endpoint_deactivation_settings, :deactivation_in).ago
  end

  def should_be_marked_for_deactivation?
    return false if deactivated?
    return false if deactivation_limit_reached_at

    max_attempts_period = Webhooks::Outgoing::Delivery.max_attempts_period + 1.hour # Adding 1 hour to ensure it covers all delays
    max_limit = BulletTrain::OutgoingWebhooks::Engine.config.outgoing_webhooks.dig(:automatic_endpoint_deactivation_settings, :max_limit)
    last_successful_delivery = deliveries.where.not(delivered_at: nil).maximum(:delivered_at)
    # There is a recent successful delivery, so we don't deactivate
    return false if last_successful_delivery && last_successful_delivery > (Webhooks::Outgoing::Delivery.max_attempts_period + 1.hour).ago

    # All recent deliveries are failed and it's number is enough to trigger deactivation
    failed_deliveries = deliveries.where(delivered_at: nil).where("created_at < ?", max_attempts_period.ago).last(max_limit).pluck(:delivered_at)
    return false if failed_deliveries.empty?

    failed_deliveries.all?(&:nil?) && failed_deliveries.size >= max_limit
  end

  def notify_deactivation_limit_reached
    Webhooks::Outgoing::EndpointMailer.deactivation_limit_reached(self).deliver_later
  end

  def notify_deactivated
    Webhooks::Outgoing::EndpointMailer.deactivated(self).deliver_later
  end
end
