module Account::Onboarding::InvitationLists::ControllerBase
  extend ActiveSupport::Concern

  included do
    layout "devise"

    before_action do
      # TODO: Is this okay?
      @user = current_user
    end
  end

  def new
    @account_onboarding_invitation_list = Account::Onboarding::InvitationList.new
  end

  def create
    @account_onboarding_invitation_list = Account::Onboarding::InvitationList.new(account_onboarding_invitation_list_params)

    # Set default values for invitations and memberships.
    # `save` below checks if the values are valid or not.
    @account_onboarding_invitation_list.team = current_team
    @account_onboarding_invitation_list.invitations.each_with_index do |invitation, idx|
      invitation.team = current_team
      invitation.from_membership = current_membership
      invitation.membership.team = current_team
      invitation.membership.user_email = invitation.email
    end

    respond_to do |format|
      if @account_onboarding_invitation_list.save
        format.html { redirect_to account_team_path(@user.teams.first), notice: "" }
        format.json { render :show, status: :ok, location: [:account, @user] }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @account_onboarding_invitation_list.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def account_onboarding_invitation_list_params
    params.require(:account_onboarding_invitation_list).permit(
      invitations_attributes: [
        :email,
        membership_attributes: [
          role_ids: []
        ]
      ]
    )
  end

  def current_membership
    current_user.memberships.find_by(team: current_team)
  end

  # Since there is only one membership (an admin) on the team when sending bulk invitations,
  # we don't have to worry about filtering these roles according to if they're manageable or not.
  def available_roles
    current_membership.roles.map { |role| [role.attributes[:key]] + role.attributes[:manageable_roles] }.flatten.uniq.reject { |role| role.match?("default") }
  end
end
