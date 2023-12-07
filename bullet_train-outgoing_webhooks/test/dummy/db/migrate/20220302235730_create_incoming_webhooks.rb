class CreateIncomingWebhooks < ActiveRecord::Migration[7.0]
  def change
    create_table :bullet_train_webhooks do |t|
      t.jsonb "data"
      t.datetime "processed_at", precision: nil
      t.datetime "verified_at", precision: nil

      t.timestamps
    end
  end
end
