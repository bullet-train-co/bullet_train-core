# frozen_string_literal: true

class Team < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :scaffolding_absolutely_abstract_creative_concepts, class_name: "Scaffolding::AbsolutelyAbstract::CreativeConcept", dependent: :destroy

  has_many :users, through: :memberships

  validates :name, presence: true
end
