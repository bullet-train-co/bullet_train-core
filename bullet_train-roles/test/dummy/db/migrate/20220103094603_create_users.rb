class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :email
      t.string :first_name
      t.string :last_name
      t.integer :current_team_id
      t.jsonb :ability_cache

      t.timestamps
    end
  end
end
