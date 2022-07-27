class Webhooks::Outgoing::Event < BulletTrain::OutgoingWebhooks.base_class.constantize
  include Webhooks::Outgoing::EventSupport
end
