class Webhooks::Outgoing::PurgeJob < ApplicationJob
  queue_as :default

  def perform(days_old = 90)
    purge(Webhooks::Outgoing::Event, days_old)
    purge(Webhooks::Outgoing::Delivery, days_old)
    purge(Webhooks::Outgoing::DeliveryAttempt, days_old)
  end

  def purge(model, days_old)
    records = model.where("created_at < ?", days_old.days.ago)
    records.destroy_all
  end
end
