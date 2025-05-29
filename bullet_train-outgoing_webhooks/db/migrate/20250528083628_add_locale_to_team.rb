class AddLocaleToTeam < ActiveRecord::Migration[8.0]
  def change
    add_column :teams, :locale, :string
  end
end
