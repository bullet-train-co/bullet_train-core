module Account::Onboarding::InvitationLists::Base
  extend ActiveSupport::Concern

  included do
    belongs_to :team
    has_many :invitations

    accepts_nested_attributes_for :invitations
  end
end
