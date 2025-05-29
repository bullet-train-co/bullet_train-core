class Webhooks::Outgoing::EndpointHealth
  attr_reader :config, :settings, :deliveries_table, :endpoints_table

  def initialize
    @config = BulletTrain::OutgoingWebhooks::Engine.config.outgoing_webhooks
    @settings = OpenStruct.new(config[:automatic_deactivation_endpoint_settings])
    @deliveries_table = Webhooks::Outgoing::Delivery.table_name
    @endpoints_table = Webhooks::Outgoing::Endpoint.table_name
  end

  def mark_to_deactivate!
    return unless config[:automatic_deactivation_endpoint_enabled]

    max_attempts_period = Webhooks::Outgoing::Delivery.max_attempts_period + 1.hour # Adding 1 hour to ensure it covers all delays
    last_delivered = Webhooks::Outgoing::Delivery
      .select("MAX(id) as id", :endpoint_id)
      .where.not(delivered_at: nil)
      .group(:endpoint_id)
    active_endpoints = Webhooks::Outgoing::Endpoint
      .select(:id)
      .where(deactivation_limit_reached_at: nil, deactivated_at: nil)

    not_delivered = Webhooks::Outgoing::Delivery
      .joins("INNER JOIN (#{active_endpoints.to_sql}) AS endpoints ON #{deliveries_table}.endpoint_id = endpoints.id")
      .joins("LEFT JOIN (#{last_delivered.to_sql}) AS last_deliveries ON #{deliveries_table}.endpoint_id = last_deliveries.endpoint_id")
      .where(delivered_at: nil)
      .where("created_at < ?", max_attempts_period.ago)
      .where("#{deliveries_table}.id > COALESCE(last_deliveries.id, 0)")
      .group(:endpoint_id)
      .having("count(#{deliveries_table}.id) >= ?", settings.max_limit)
      .pluck(:endpoint_id)

    Webhooks::Outgoing::Endpoint.where(id: not_delivered).update_all(deactivation_limit_reached_at: Time.current)

    # Send notifications for endpoints marked for deactivation
    not_delivered.each do |endpoint_id|
      Webhooks::Outgoing::EndpointNotificationJob.perform_later(
        endpoint_id: endpoint_id,
        notification_type: "deactivation_limit_reached"
      )
    end

    not_delivered
  end

  def deactivate_failed_endpoints!
    return unless config[:automatic_deactivation_endpoint_enabled]
    delivered_webhooks = Webhooks::Outgoing::Delivery
      .select(:endpoint_id, "MAX(delivered_at) as delivered_at")
      .where.not(delivered_at: nil)
      .group(:endpoint_id)

    endpoints_to_deactivate = Webhooks::Outgoing::Endpoint
      .where.not(deactivation_limit_reached_at: nil)
      .where(deactivated_at: nil)
      .where("deactivation_limit_reached_at <= ?", settings.deactivation_in.ago)
      .joins("LEFT JOIN (#{delivered_webhooks.to_sql}) AS delivered_webhooks ON delivered_webhooks.endpoint_id = #{endpoints_table}.id")
      .where("delivered_webhooks.delivered_at IS NULL OR delivered_webhooks.delivered_at < ?", settings.deactivation_in.ago)
      .pluck(:id)

    Webhooks::Outgoing::Endpoint.where(id: endpoints_to_deactivate).update_all(deactivated_at: Time.current)

    # Send notifications for endpoints that have been deactivated
    endpoints_to_deactivate.each do |endpoint_id|
      Webhooks::Outgoing::EndpointNotificationJob.perform_later(
        endpoint_id: endpoint_id,
        notification_type: "deactivated"
      )
    end

    endpoints_to_deactivate
  end
end
