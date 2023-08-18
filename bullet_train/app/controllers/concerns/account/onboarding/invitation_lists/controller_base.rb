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
      :team_id,
      :sender_id,
      invitations_attributes: [
        :team_id,
        :from_membership_id,
        :email,
        membership_attributes: [
          :team_id,
          :user_first_name,
          :user_last_name,
          role_ids: []
        ]
      ]
    )
  end
end
