class CreateScaffoldingAbsolutelyAbstractCreativeConcepts < ActiveRecord::Migration[7.0]
  def change
    create_table :scaffolding_absolutely_abstract_creative_concepts do |t|
      t.string :name
      t.text :description
      t.references :team, null: false, foreign_key: true, index: {name: "index_scaffold_absolutely_abstract_creative_concept_on_team_id"}

      t.timestamps
    end
  end
end
