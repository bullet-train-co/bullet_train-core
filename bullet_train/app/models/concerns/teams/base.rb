module Teams::Base
  extend ActiveSupport::Concern

  included do
    # super scaffolding
    unless scaffolding_things_disabled?
      has_many :scaffolding_absolutely_abstract_creative_concepts, class_name: "Scaffolding::AbsolutelyAbstract::CreativeConcept", dependent: :destroy, enable_cable_ready_updates: true
    end

    # added_by_id is a foreign_key to other Memberships on the same team,
    # so we nullify this to remove the constraint to delete the team.
    before_destroy { Membership.where(team: self).update_all(added_by_id: nil) }

    # memberships and invitations
    has_many :memberships, dependent: :destroy
    has_many :users, through: :memberships
    has_many :invitations

    # oauth for grape api
    has_many :platform_applications, class_name: "Platform::Application", dependent: :destroy, foreign_key: :team_id

    # integrations
    has_many :integrations_stripe_installations, class_name: "Integrations::StripeInstallation", dependent: :destroy if stripe_enabled?

    # validations
    validates :name, presence: true
    validates :time_zone, inclusion: {in: ActiveSupport::TimeZone.all.map(&:name)}, allow_nil: true
  end

  def platform_agent_access_tokens
    Platform::AccessToken.joins(:application).where(resource_owner_id: users.where.not(platform_agent_of_id: nil), application: {team: nil})
  end

  def admins
    memberships.current_and_invited.admins
  end

  def admin_users
    admins.map(&:user).compact
  end

  def primary_contact
    admin_users.min { |user| user.created_at }
  end

  def formatted_email_address
    primary_contact.email
  end

  def invalidate_caches
    users.map(&:invalidate_ability_cache)
  end

  def team
    # some generic features appeal to the `team` method for security or scoping purposes, but sometimes those same
    # generic functions need to function for a team model as well, so we do this.
    self
  end

  ActiveSupport.run_load_hooks :bullet_train_teams_base, self
end
