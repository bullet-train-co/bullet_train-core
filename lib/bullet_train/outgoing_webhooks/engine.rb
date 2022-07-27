module BulletTrain
  module OutgoingWebhooks
    class Engine < ::Rails::Engine
      initializer "bullet_train.outgoing_webhooks.register_api_endpoints" do |app|
        if defined?(BulletTrain::Api)
          BulletTrain::Api.endpoints << "Api::V1::Webhooks::Outgoing::EndpointsEndpoint"
          BulletTrain::Api.endpoints << "Api::V1::Webhooks::Outgoing::DeliveriesEndpoint"
          BulletTrain::Api.endpoints << "Api::V1::Webhooks::Outgoing::DeliveryAttemptsEndpoint"
        end
      end
    end
  end
end
