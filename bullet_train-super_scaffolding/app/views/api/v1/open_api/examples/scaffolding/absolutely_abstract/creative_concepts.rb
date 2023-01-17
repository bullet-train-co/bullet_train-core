BulletTrain::Api.define do
  example :scaffolding_absolutely_abstract_creative_concept, class: "Scaffolding::AbsolutelyAbstract::CreativeConcept" do
    team { BulletTrain::Api.example(:team, scaffolding_absolutely_abstract_creative_concepts: [self.instance]) }
    name { "Example Creative Concept" }
    description { "Example Text" }
  end
end
