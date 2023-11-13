# frozen_string_literal: true

class Scaffolding::AbsolutelyAbstract::CreativeConcept < ApplicationRecord
  belongs_to :team

  validates :name, presence: true
end
