class Account::Onboarding::InvitationList < ApplicationRecord
  include Account::Onboarding::InvitationLists::Base

  def self.table_name_prefix
    "account_onboarding_"
  end
end
