class AddFailedCountToWebhookEndpoints < ActiveRecord::Migration[8.0]
  def change
    add_column :webhooks_outgoing_endpoints, :consecutive_failed_deliveries, :integer, default: 0, null: false
  end
end
