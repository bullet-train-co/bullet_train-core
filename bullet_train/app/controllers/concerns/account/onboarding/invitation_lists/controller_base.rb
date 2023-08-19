module Account::Onboarding::InvitationLists::ControllerBase
  extend ActiveSupport::Concern

  included do
    layout "devise"

    # TODO: Check if we need these, and also for the InvitationList resource.
    # load_and_authorize_resource class: "User"
    # load_and_authorize_resource class: "Team"

    before_action do
      @user = current_user
      @team = current_team
    end
  end

  def new
    @account_onboarding_invitation_list = Account::Onboarding::InvitationList.new
  end

  def create
    @account_onboarding_invitation_list = Account::Onboarding::InvitationList.create(account_onboarding_invitation_list_params)

    # Set default values for invitations and memberships.
    @account_onboarding_invitation_list.update(team: @team)
    @account_onboarding_invitation_list.invitations.each do |invitation|
      invitation.update(team: @team, from_membership: current_membership)
      invitation.membership.update(team: @team)
    end

    respond_to do |format|
      # We don't actually create a InvitationList record here, so we use `valid?` instead of `save`.
      if @account_onboarding_invitation_list.valid?
        # TODO: Send all the invitations. Write response for JSON format.
        format.html { redirect_to new_account_onboarding_invitation_list_path(@user) }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @account_onboarding_invitation_list.errors, status: :unprocessable_entity}
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
    @user.memberships.find_by(team: @team)
  end
end
