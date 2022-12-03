# frozen_string_literal: true

class Membership < ApplicationRecord
  include Roles::Support

  belongs_to :user, optional: true
  belongs_to :team

  has_many :scaffolding_absolutely_abstract_creative_concepts_collaborators, class_name: "Scaffolding::AbsolutelyAbstract::CreativeConcepts::Collaborator", dependent: :destroy
end
