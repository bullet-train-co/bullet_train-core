class Scaffolding::AbsolutelyAbstract::CreativeConcept < ApplicationRecord
  # 🚅 add concerns above.

  belongs_to :team
  # 🚅 add belongs_to associations above.

  # TODO: We shouldn't have to explicitly set the order here, so we need to find out why these records
  # are being returned in descending order when calling @creative_concept.completely_concrete_tangible_things.
  has_many :completely_concrete_tangible_things, -> { order(:id) }, class_name: "Scaffolding::CompletelyConcrete::TangibleThing", foreign_key: :absolutely_abstract_creative_concept_id, dependent: :destroy
  # 🚅 add has_many associations above.

  # 🚅 add oauth providers above.

  # 🚅 add has_one associations above.

  # 🚅 add scopes above.

  validates :name, presence: true
  # 🚅 add validations above.

  # 🚅 add callbacks above.

  # 🚅 add delegations above.

  # 🚅 add methods above.
end
