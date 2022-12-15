class Webhooks::Outgoing::GenerateJob < ApplicationJob
  queue_as :default

  def perform(obj, action)
    obj.generate_webhook_perform(action)
  end
end
