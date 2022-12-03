# frozen_string_literal: true

class Scaffolding::AbsolutelyAbstract::CreativeConcept < ApplicationRecord
  belongs_to :team

  has_many :collaborators, class_name: "Scaffolding::AbsolutelyAbstract::CreativeConcepts::Collaborator", dependent: :destroy, foreign_key: :creative_concept_id

  has_many :memberships, through: :collaborators

  validates :name, presence: true
end
