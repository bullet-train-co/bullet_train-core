class CreateScaffoldingAbsolutelyAbstractCreativeConceptsCollaborators < ActiveRecord::Migration[7.0]
  def change
    create_table :scaffolding_absolutely_abstract_creative_concepts_collaborators do |t|
      t.jsonb :role_ids
      t.references :creative_concept, null: false, foreign_key: {to_table: "scaffolding_absolutely_abstract_creative_concepts"}, index: {name: "index_creative_concepts_collaborators_on_creative_concept_id"}
      t.references :membership, null: false, index: {name: "index_creative_concepts_collaborators_on_membership_id"}

      t.timestamps
    end
  end
end
