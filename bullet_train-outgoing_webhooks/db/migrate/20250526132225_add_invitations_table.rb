class AddInvitationsTable < ActiveRecord::Migration[8.0]
  def change
    create_table "invitations", id: :serial, force: :cascade do |t|
      t.string "email"
      t.string "uuid"
      t.integer "from_membership_id"
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.integer "team_id"
      t.bigint "invitation_list_id"
      t.index ["invitation_list_id"], name: "index_invitations_on_invitation_list_id"
      t.index ["team_id"], name: "index_invitations_on_team_id"
    end
    add_reference :memberships, :invitation, index: true
  end
end
