class AddApiVersionToWebhooksOutgoingEndpoints < ActiveRecord::Migration[7.0]
  def change
    add_column :webhooks_outgoing_endpoints, :api_version, :string, null: false
  end
end
