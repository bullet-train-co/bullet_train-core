# frozen_string_literal: true

require "cancan"

class Ability
  include CanCan::Ability
  include Roles::Permit

  def initialize(user)
    if user.present?
      permit user, through: :memberships, parent: :team
      permit user, through: :scaffolding_absolutely_abstract_creative_concepts_collaborators, parent: :creative_concept

      # INDIVIDUAL USER PERMISSIONS.
      can :manage, User, id: user.id
      can :destroy, Membership, user_id: user.id

      can :create, Team
    end
  end
end
