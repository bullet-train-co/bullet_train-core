# frozen_string_literal: true

class User < ApplicationRecord
  include Roles::User
  belongs_to :current_team, class_name: "Team", optional: true

  has_many :memberships, dependent: :destroy

  has_many :teams, through: :memberships

  has_many :scaffolding_absolutely_abstract_creative_concepts_collaborators, through: :memberships

  def create_default_team
    # This creates a `Membership`, because `User` `has_many :teams, through: :memberships`
    default_team = teams.create!(name: "Your Team")

    memberships.find_by(team: default_team).update(role_ids: [Role.admin.id])

    update(current_team: default_team)
  end
end
