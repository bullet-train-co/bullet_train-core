class Webhooks::Outgoing::EndpointsDeactivationWorker
  include Sidekiq::Worker

  def perform
    return unless automatic_deactivation_endpoint_enabled?

    endpoint_health = Webhooks::Outgoing::EndpointHealth.new
    endpoint_health.deactivate_failed_endpoints!
    endpoint_health.mark_to_deactivate!
  end

  private

  def automatic_deactivation_endpoint_enabled?
    BulletTrain::OutgoingWebhooks::Engine.config.outgoing_webhooks[:automatic_deactivation_endpoint_enabled]
  end
end
