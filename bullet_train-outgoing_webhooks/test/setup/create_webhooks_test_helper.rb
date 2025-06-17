module CreateWebhooksTestHelpers
  def create_user(options = {})
    User.create!(
      email: options[:email] || "test@example.com",
      password: options[:password] || "password",
    )
  end

  def create_endpoint(options = {})
    Webhooks::Outgoing::Endpoint.create!(
      url: options[:url] || "https://example.com/webhook",
      name: options[:name] || "test",
      team: options[:team] || @team,
      event_type_ids: options[:event_type_ids] || ["fake-thing.create"],
      deactivation_limit_reached_at: options[:deactivation_limit_reached_at] || nil,
      deactivated_at: options[:deactivated_at] || nil,
      consecutive_failed_deliveries: options[:consecutive_failed_deliveries] || 0,
    )
  end

  def create_event(options = {})
    Webhooks::Outgoing::Event.create!(
      subject: options[:subject] || create_user,
      event_type_id: options[:event_type_id] || "fake-thing.create",
      team: options[:team] || @team,
      payload: options[:payload] || {data: "test"},
      api_version: options[:api_version] || 1,
    )
  end

  def create_delivery(options = {})
    Webhooks::Outgoing::Delivery.create!(
      endpoint: options[:endpoint] || create_endpoint,
      event: options[:event] || create_event,
      endpoint_url: options[:endpoint_url] || "https://example.com/webhook",
      delivered_at: options[:delivered_at] || nil,
      created_at: options[:created_at] || Time.current
    )
  end

  def create_list_of_deliveries(count, options = {})
    deliveries = []
    count.times do
      deliveries << create_delivery(options)
    end
    deliveries
  end

  def create_delivery_attempts(delivery, count, options = {})
    count.times do |i|
      delivery.delivery_attempts.create!(
        attempt_number: i + 1,
        response_code: options[:response_code] || 500,
        error_message: options[:error_message] || "Server error",
        created_at: options[:created_at] || Time.current
      )
    end
  end

  def created_at_that_considered_failed
    Webhooks::Outgoing::Delivery.max_attempts_period.ago - 1.hour
  end
end
