class CreateDocuments < ActiveRecord::Migration[7.0]
  def change
    create_table :documents do |t|
      t.references :membership, null: false, foreign_key: true
      t.string :name

      t.timestamps
    end
  end
end
