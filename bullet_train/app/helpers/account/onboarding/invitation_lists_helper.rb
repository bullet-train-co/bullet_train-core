module Account::Onboarding::InvitationListsHelper
  # When sending bulk invitations, the current user is the only one with a membership on the team.
  # This means that we can access all of the available roles with the following code.
  def available_roles
    role_ids = current_user.memberships.first.roles.map do |role|
      [role.attributes[:key]] + role.attributes[:manageable_roles]
    end.flatten.uniq

    role_ids.map { |role| role.capitalize }
  end
end
