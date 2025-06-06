class Webhooks::Outgoing::EndpointNotificationJob < ApplicationJob
  queue_as :mailers

  def perform(endpoint_id:, notification_type:)
    endpoint = Webhooks::Outgoing::Endpoint.find(endpoint_id)

    case notification_type
    when "deactivation_limit_reached"
      Webhooks::Outgoing::EndpointMailer.deactivation_limit_reached(endpoint)&.deliver_now
    when "deactivated"
      Webhooks::Outgoing::EndpointMailer.deactivated(endpoint)&.deliver_now
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "EndpointNotificationJob: Endpoint not found for ID #{endpoint_id}"
  end
end
