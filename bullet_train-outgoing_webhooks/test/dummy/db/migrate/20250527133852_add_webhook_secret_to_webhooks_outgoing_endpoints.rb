class AddWebhookSecretToWebhooksOutgoingEndpoints < ActiveRecord::Migration[8.0]
  def change
    add_column :webhooks_outgoing_endpoints, :webhook_secret, :string, null: false
  end
end
