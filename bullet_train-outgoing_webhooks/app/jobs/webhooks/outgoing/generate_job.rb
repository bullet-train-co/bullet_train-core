class Webhooks::Outgoing::GenerateJob < ApplicationJob
  queue_as :default

  # `= [1]` ensures backwards compatibility for older installations when they upgrade.
  def perform(obj, action, api_versions = [1])
    obj.generate_webhook_perform(action, api_versions)
  end
end
