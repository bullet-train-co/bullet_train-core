# frozen_string_literal: true

class User < ApplicationRecord
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

  def invalidate_ability_cache
    update_column(:ability_cache, {})
  end

  def parent_ids_for(role, through, parent)
    parent_id_column = "#{parent}_id"
    key = "#{role.key}_#{through}_#{parent_id_column}s"

    return ability_cache[key] if ability_cache && ability_cache[key]

    role = nil if role.default?
    value = send(through).with_role(role).distinct.pluck(parent_id_column)
    current_cache = ability_cache || {}
    current_cache[key] = value

    update_column :ability_cache, current_cache

    value
  end
end
