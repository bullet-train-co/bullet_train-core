class UpdateUsersTableForDummyApp < ActiveRecord::Migration[8.0]
  def change
    change_table :users do |t|
      t.string "reset_password_token"
      t.datetime "reset_password_sent_at", precision: nil
      t.datetime "remember_created_at", precision: nil
      t.integer "sign_in_count", default: 0, null: false
      t.datetime "current_sign_in_at", precision: nil
      t.datetime "last_sign_in_at", precision: nil
      t.inet "current_sign_in_ip"
      t.inet "last_sign_in_ip"
      t.datetime "last_seen_at", precision: nil
      t.string "profile_photo_id"
      t.datetime "last_notification_email_sent_at", precision: nil
      t.boolean "former_user", default: false, null: false
      t.string "encrypted_otp_secret"
      t.string "encrypted_otp_secret_iv"
      t.string "encrypted_otp_secret_salt"
      t.integer "consumed_timestep"
      t.boolean "otp_required_for_login"
      t.string "otp_backup_codes", array: true
      t.string "locale"
      t.bigint "platform_agent_of_id"
      t.string "otp_secret"
      t.integer "failed_attempts", default: 0, null: false
      t.string "unlock_token"
      t.datetime "locked_at"
      t.index ["email"], name: "index_users_on_email", unique: true
      t.index ["platform_agent_of_id"], name: "index_users_on_platform_agent_of_id"
      t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
      t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    end
  end
end
