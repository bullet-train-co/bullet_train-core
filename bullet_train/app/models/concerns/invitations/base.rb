module Invitations::Base
  extend ActiveSupport::Concern

  included do
    belongs_to :team
    belongs_to :from_membership, class_name: "Membership"
    has_one :membership, dependent: :nullify
    has_many :roles, through: :membership

    accepts_nested_attributes_for :membership

    validates :email, presence: true, uniqueness: {scope: :team}

    after_create :set_added_by_membership
    after_create :send_invitation_email

    attribute :uuid, default: -> { SecureRandom.hex }
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
end
