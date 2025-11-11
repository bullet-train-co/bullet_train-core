module Invitations::Base
  extend ActiveSupport::Concern

  included do
    belongs_to :team
    belongs_to :from_membership, class_name: "Membership"
    belongs_to :invitation_list, class_name: "Account::Onboarding::InvitationList", optional: true
    has_one :membership, dependent: :nullify

    accepts_nested_attributes_for :membership

    validates :email, presence: true, uniqueness: {scope: :team}

    after_create :set_added_by_membership
    after_create :send_invitation_email

    after_validation :hoist_membership_email_error

    attribute :uuid, default: -> { SecureRandom.hex }

    def roles
      membership.roles
    end
  end

  def set_added_by_membership
    membership.update(added_by: from_membership)
  end

  def send_invitation_email
    UserMailer.invited(uuid).deliver_later
  end

  def accept_for(user)
    User.transaction do
      user.memberships << membership
      user.update(current_team: team, former_user: false)
      destroy
    end
  end

  def name
    I18n.t("invitations.values.name", team_name: team.name)
  end

  def is_for?(user)
    user.email.downcase.strip == email.downcase.strip
  end

  def hoist_membership_email_error
    # This is special handling for the email field because we have a uniquness validation in the
    # `Membership` model for the `user_email` field. Since we copy the value from `invitation.email`
    # into `invitation.membership.user_email` the error isn't passed through to the form in the normal way.
    if errors[:"membership.user_email"]
      errors[:"membership.user_email"].each do |error|
        errors.add(:email, error)
      end
    end
  end
end
