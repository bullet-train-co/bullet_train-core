class Webhooks::Outgoing::PurgeJob < ApplicationJob
  queue_as :default

  def perform(days_old = 90)
    purge("Webhooks::Outgoing::Event", days_old)
    purge("Webhooks::Outgoing::Delivery", days_old)
    purge("Webhooks::Outgoing::DeliveryAttempt", days_old)
    
    # events = "Webhooks::Outgoing::Event".constantize.where("created_at < ?", days_old.days.ago)
    # events.destroy_all

    # deliveries = "Webhooks::Outgoing::Delivery".constantize.where("created_at < ?", days_old.days.ago)
    # deliveries.destroy_all

    # delivery_attempts = "Webhooks::Outgoing::DeliveryAttempt".constantize.where("created_at < ?", days_old.days.ago)
    # delivery_attempts.destroy_all
  end

  def purge(table_name, days_old)
    records = table_name.constantize.where("created_at < ?", days_old.days.ago)
    records.destroy_all
  end
end
