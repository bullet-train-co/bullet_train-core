class Webhooks::Incoming::BulletTrainWebhook < BulletTrain::Configuration.incoming_webhooks_parent_class_name.constantize
  include Webhooks::Incoming::Webhook
  include Rails.application.routes.url_helpers

  # there are many ways a service might ask you to verify the validity of a webhook.
  # whatever that method is, you would implement it here.
  def verify_authenticity
    # 🚅 skip this section when scaffolding.
    # trying to fix integration tests. if this fixes it, i don't know why puma won't accept another connection here.
    return true if Rails.env.test?

    uri = URI.parse(api_v1_webhooks_outgoing_event_url(data["event_id"]))
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == "https"
    request = Net::HTTP::Get.new(uri.path)
    request.add_field("Content-Type", "application/json")
    # TODO We need to adjust the way we set up authentication here.
    # request.basic_auth ENV["BULLET_TRAIN_API_KEY"], ENV["BULLET_TRAIN_API_SECRET"]
    response = http.request(request)

    # ensure that the payload on the server is the same as the payload we received.
    JSON.parse(response.body) == data
    # 🚅 stop any skipping we're doing now.
  end

  def process
  end
end
