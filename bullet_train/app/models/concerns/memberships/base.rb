module Memberships::Base
  extend ActiveSupport::Concern

  included do
    attr_accessor :user_profile_photo_removal

    # See `docs/permissions.md` for details.
    include Roles::Support

    belongs_to :user, optional: true
    belongs_to :team
    belongs_to :invitation, optional: true, dependent: :destroy
    belongs_to :added_by, class_name: "Membership", optional: true
    belongs_to :platform_agent_of, class_name: "Platform::Application", optional: true

    has_many :scaffolding_completely_concrete_tangible_things_assignments, class_name: "Scaffolding::CompletelyConcrete::TangibleThings::Assignment", dependent: :destroy
    has_many :scaffolding_completely_concrete_tangible_things, through: :scaffolding_completely_concrete_tangible_things_assignments, source: :tangible_thing

    has_many :scaffolding_absolutely_abstract_creative_concepts_collaborators, class_name: "Scaffolding::AbsolutelyAbstract::CreativeConcepts::Collaborator", dependent: :destroy

    # Image uploading
    has_one_attached :user_profile_photo

    validates :user_email, uniqueness: {scope: :team}

    after_destroy do
      # if we're destroying a user's membership to the team they have set as
      # current, then we need to remove that so they don't get an error.
      if user&.current_team == team
        user.current_team = nil
        user.save
      end
    end

    after_validation :remove_user_profile_photo, if: :user_profile_photo_removal?

    scope :excluding_platform_agents, -> { where(platform_agent_of: nil) }
    scope :platform_agents, -> { where.not(platform_agent_of: nil) }
    scope :current_and_invited, -> { includes(:invitation).where("user_id IS NOT NULL OR invitations.id IS NOT NULL").references(:invitation) }
    scope :current, -> { where("user_id IS NOT NULL") }
    scope :tombstones, -> { includes(:invitation).where("user_id IS NULL AND invitations.id IS NULL AND platform_agent IS FALSE").references(:invitation) }
  end

  def name
    full_name
  end

  def label_string
    full_name
  end

  # we overload this method so that when setting the list of role ids
  # associated with a membership, admins can never remove the last admin
  # of a team.
  def role_ids=(ids)
    # if this membership was an admin, and the new list of role ids don't include admin.
    if admin? && !ids.include?(Role.admin.id)
      unless team.admins.count > 1
        raise RemovingLastTeamAdminException.new("You can't remove the last team admin.")
      end
    end

    super(ids)
  end

  def unclaimed?
    user.nil? && !invitation.nil?
  end

  def tombstone?
    user.nil? && invitation.nil? && !platform_agent
  end

  def last_admin?
    return false unless admin?
    return false unless user.present?
    team.memberships.current.select(&:admin?) == [self]
  end

  def nullify_user
    if last_admin?
      raise RemovingLastTeamAdminException.new("You can't remove the last team admin.")
    end

    if (user_was = user)
      unless user_first_name.present?
        self.user_first_name = user.first_name
      end

      unless user_last_name.present?
        self.user_last_name = user.last_name
      end

      unless user_profile_photo_id.present?
        self.user_profile_photo_id = user.profile_photo_id
      end

      unless user_email.present?
        self.user_email = user.email
      end

      self.user = nil
      save

      user_was.invalidate_ability_cache

      user_was.update(
        current_team: user_was.teams.first,
        former_user: user_was.teams.empty?
      )
    end

    # we do this here just in case by some weird chance an active membership had an invitation attached.
    invitation&.destroy
  end

  def email
    user&.email || user_email.presence || invitation&.email
  end

  def full_name
    user&.full_name || [first_name.presence, last_name.presence].join(" ").presence || email
  end

  def first_name
    user&.first_name || user_first_name
  end

  def last_name
    user&.last_name || user_last_name
  end

  def last_initial
    return nil unless last_name.present?
    "#{last_name[0]}."
  end

  def first_name_last_initial
    [first_name, last_initial].select(&:present?).join(" ")
  end

  # TODO utilize this.
  # members shouldn't receive notifications unless they are either an active user or an outstanding invitation.
  def should_receive_notifications?
    invitation.present? || user.present?
  end

  def user_profile_photo_removal?
    user_profile_photo_removal.present?
  end

  def remove_user_profile_photo
    user_profile_photo.purge
  end

  ActiveSupport.run_load_hooks :bullet_train_memberships_base, self
end
