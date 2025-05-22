class Webhooks::Outgoing::EndpointHealth
  attr_reader :config, :settings

  def initialize
    @config = BulletTrain::OutgoingWebhooks::Engine.config.outgoing_webhooks
    @settings = OpenStruct.new(config[:automatic_deactivation_endpoint_settings])
  end

  def mark_to_deactivate!
    return unless config[:automatic_deactivation_endpoint_enabled]

    deliveries_table = Webhooks::Outgoing::Delivery.table_name
    last_delivered = Webhooks::Outgoing::Delivery
      .select("MAX(id) as id", :endpoint_id)
      .where.not(delivered_at: nil)
      .group(:endpoint_id)
    active_endpoints = Webhooks::Outgoing::Endpoint
      .select(:id)
    # .where(deactivation_limit_reached_at: nil, deactivated_at: nil)

    not_delivered = Webhooks::Outgoing::Delivery
      .select("MIN(#{deliveries_table}.id) as first_id", "count(#{deliveries_table}.id) count_failed", :endpoint_id) # debug select
      # .select(:endpoint_id) # release select
      .joins("INNER JOIN (#{active_endpoints.to_sql}) AS endpoints ON #{deliveries_table}.endpoint_id = endpoints.id")
      .joins("LEFT JOIN (#{last_delivered.to_sql}) AS last_deliveries ON #{deliveries_table}.endpoint_id = last_deliveries.endpoint_id")
      .where(delivered_at: nil)
      .where("#{deliveries_table}.id > COALESCE(last_deliveries.id, 0)")
      .group(:endpoint_id)
      .having("count(#{deliveries_table}.id) >= ?", settings.max_limit)

    not_delivered.pluck(:endpoint_id)
  end

  def deactivate_failed_endpoints!
    return unless config[:automatic_deactivation_endpoint_enabled]

    disabled_endpoints = []
    # Deactivate endpoints that have only failed deliveries
    endpoints_with_only_failed_deliveries.each do |endpoint_id, count|
      if count >= settings.max_limit
        # TODO mark the endpoint as deactivated
        disabled_endpoints << endpoint_id
        puts "Endpoint #{endpoint_id} has #{count} failed deliveries. Marking as deactivated."
      end
    end

    # Deactivate endpoints that have only failed deliveries last X days
    failed_endpoints_ids = failed_deliveries_by_date
    if failed_endpoints_ids.any?
      failed_endpoints_ids.each do |endpoint_id|
        # TODO mark the endpoint as deactivated
        disabled_endpoints << endpoint_id
        puts "Endpoint #{endpoint_id} has failed deliveries because of date. Mark it as deactivated."
      end
    end

    # Deactivate endpoints that have X failed deliveries in a row
    failed_endpoints_ids = failed_deliveries_by_count
    if failed_endpoints_ids.any?
      failed_endpoints_ids.each do |endpoint_id|
        # TODO mark the endpoint as deactivated
        disabled_endpoints << endpoint_id
        puts "Endpoint #{endpoint_id} has failed deliveries because of count. Marking as deactivated."
      end
    end

    disabled_endpoints
  end

  private

  def failed_deliveries_by_date
    failed_endpoints_ids = []
    Webhooks::Outgoing::Delivery.where(delivered_at: nil).where("created_at < ?", settings.initial_tolerance_window.ago).each do |delivery|
      first_undeliverables_per_endpoint.each do |endpoint_id, delivery|
        if delivery.created_at < settings.initial_tolerance_window.ago
          failed_endpoints_ids << endpoint_id
        end
      end
    end
    failed_endpoints_ids
  end

  def failed_deliveries_by_count
    failed_endpoints_ids = []
    first_undeliverables_per_endpoint.each do |endpoint_id, delivery|
      count_failed_scope = Deliveries::Outgoing::Delivery.where(endpoint_id: endpoint_id).where("id >= ?", delivery.id)
      if (count_failed = count_failed_scope.count) >= settings.max_limit
        puts "Endpoint #{endpoint_id} has #{count_failed} failed deliveries since."
        failed_endpoints_ids << endpoint_id
      end
    end
    failed_endpoints_ids
  end

  def endpoints_with_only_failed_deliveries
    any_delivered_subquery = Webhooks::Outgoing::Delivery.where.not(delivered_at: nil).select(:endpoint_id)
    Webhooks::Outgoing::Delivery
      .where(delivered_at: nil)
      .where.not(endpoint_id: any_delivered_subquery)
      .group(:endpoint_id)
      .count
  end

  # returns {endpoint_id => last_delivered_id, ...}
  def last_delivered_ids
    @_last_delivered_ids ||= Webhooks::Outgoing::Delivery.where.not(delivered_at: nil)
      .group(:endpoint_id)
      .maximum(:id)
  end

  # returns {endpoint_id => delivery, ...}
  def first_undeliverables_per_endpoint
    @_first_undeliverables_per_endpoint ||= begin
      res = {}

      last_delivered_ids.each do |endpoint_id, last_delivered_id|
        delivery = Webhooks::Outgoing::Delivery.where(endpoint_id: endpoint_id, delivered_at: nil)
          .where("id > ?", last_delivered_id)
          .order(:id)
          .first
        res[endpoint_id] = delivery if delivery
      end
      res
    end
  end
end
