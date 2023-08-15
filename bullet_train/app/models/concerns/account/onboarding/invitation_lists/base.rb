module Account::Onboarding::InvitationLists::Base
  extend ActiveSupport::Concern

  included do
    belongs_to :team
    has_many :invitations
    has_many :memberships, through: :invitations

    accepts_nested_attributes_for :invitations, :memberships
  end
end
