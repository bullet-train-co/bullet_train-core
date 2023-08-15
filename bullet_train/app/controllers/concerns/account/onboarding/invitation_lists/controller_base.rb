module Account::Onboarding::InvitationLists::ControllerBase
  extend ActiveSupport::Concern

  included do
    layout "devise"
    load_and_authorize_resource class: "User"
    load_and_authorize_resource class: "Team"

    before_action do
      @user = current_user
      @team = current_team
    end
  end

  def new
    @invitation_list = Account::Onboarding::InvitationList.new
  end

  # We don't actually create a InvitationList record here,
  # it's simply a placeholder to generate new invitations.
  def create
    # TODO: Send invitations here.
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def invitation_list_params
    params.permit(:account_onboarding_invitation_list).require(
      invitations_attributes: [
        :email,
        membership_attributes: [
          role_ids: []
        ]
      ]
    )
  end
end
