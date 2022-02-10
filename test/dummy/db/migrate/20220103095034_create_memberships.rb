class CreateMemberships < ActiveRecord::Migration[7.0]
  def change
    create_table :memberships do |t|
      # We deliberately _don't_ set a default here because it's not possible to set a default with mysql.
      # To make the gem compatible with more db_adapters out of the box, we should only use features that are available in all databases
      t.jsonb :role_ids
      t.references :user, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true

      t.timestamps
    end
  end
end
