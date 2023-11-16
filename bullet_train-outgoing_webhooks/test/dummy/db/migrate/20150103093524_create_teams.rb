class CreateTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :teams do |t|
      t.string :name
      t.string :slug
      t.string :time_zone
      t.boolean :being_destroyed

      t.timestamps
    end
  end
end
