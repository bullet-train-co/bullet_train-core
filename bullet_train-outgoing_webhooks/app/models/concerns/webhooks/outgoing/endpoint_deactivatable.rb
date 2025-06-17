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

  def reset_failed_deliveries_marks!
    update_columns(deactivation_limit_reached_at: nil, consecutive_failed_deliveries: 0)
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

    increment!(:consecutive_failed_deliveries)

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

    max_limit = BulletTrain::OutgoingWebhooks::Engine.config.outgoing_webhooks.dig(:automatic_endpoint_deactivation_settings, :max_limit)
    consecutive_failed_deliveries >= max_limit
  end

  def notify_deactivation_limit_reached
    Webhooks::Outgoing::EndpointMailer.deactivation_limit_reached(self).deliver_later
  end

  def notify_deactivated
    Webhooks::Outgoing::EndpointMailer.deactivated(self).deliver_later
  end
end
