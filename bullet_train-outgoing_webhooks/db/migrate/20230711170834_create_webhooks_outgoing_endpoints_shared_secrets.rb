class CreateWebhooksOutgoingEndpointsSharedSecrets < ActiveRecord::Migration[7.0]
  def change
    create_table :webhooks_outgoing_endpoints_shared_secrets do |t|
      t.references :endpoint, null: false, foreign_key: true
      t.string :secret, null: false
      t.timestamp :expires_at

      t.timestamps
    end
  end
end
