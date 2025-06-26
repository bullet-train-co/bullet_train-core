class AddDeactivationFieldsToEndpoints < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_column :webhooks_outgoing_endpoints, :deactivation_limit_reached_at, :datetime
    add_column :webhooks_outgoing_endpoints, :deactivated_at, :datetime
    parent_association = BulletTrain::OutgoingWebhooks.parent_association.to_s.foreign_key.to_sym
    add_index :webhooks_outgoing_endpoints, [parent_association, :deactivated_at], algorithm: :concurrently
  end
end
