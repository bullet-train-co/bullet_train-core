class Scaffolding::AbsolutelyAbstract::CreativeConcepts::Collaborator < ApplicationRecord
  include Roles::Support

  belongs_to :creative_concept
  belongs_to :membership

  has_one :team, through: :creative_concept

  validates :membership_id, presence: true
end
