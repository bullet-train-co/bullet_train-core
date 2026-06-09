class Webhooks::Outgoing::PurgeJob < ApplicationJob
  queue_as :default

  def perform(days_old = 90)
    # Delete children first, then parents.
    purge(Webhooks::Outgoing::DeliveryAttempt, days_old)
    purge(Webhooks::Outgoing::Delivery, days_old)
    purge(Webhooks::Outgoing::Event, days_old)
  end

  def purge(model, days_old)
    model.where("created_at < ?", days_old.days.ago).delete_all
  end
end
