class Webhooks::Outgoing::EndpointsDeactivationJob < ApplicationJob
  queue_as :default

  def perform
    return unless automatic_endpoint_deactivation_enabled?

    endpoint_health = Webhooks::Outgoing::EndpointHealth.new
    endpoint_health.deactivate_failed_endpoints!
    endpoint_health.mark_to_deactivate!
  end

  private

  def automatic_endpoint_deactivation_enabled?
    BulletTrain::OutgoingWebhooks::Engine.config.outgoing_webhooks[:automatic_endpoint_deactivation_enabled]
  end
end
