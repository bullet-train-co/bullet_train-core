module Api::V1::Invitations::ControllerBase
  extend ActiveSupport::Concern

  module StrongParameters
    # Only allow a list of trusted parameters through.
    def invitation_params
      strong_params = params.require(:invitation).permit(
        *permitted_fields,
        :email,
        # 🚅 super scaffolding will insert new fields above this line.
        *permitted_arrays,
        # 🚅 super scaffolding will insert new arrays above this line
      )

      process_params(strong_params)

      strong_params
    end
  end

  included do
    load_and_authorize_resource :invitation, class: "Invitation", prepend: true,
      member_actions: (defined?(MEMBER_ACTIONS) ? MEMBER_ACTIONS : []),
      collection_actions: (defined?(COLLECTION_ACTIONS) ? COLLECTION_ACTIONS : [])

    private

    include StrongParameters
  end

  # GET /api/v1/teams/:team_id/invitations
  def index
  end

  # GET /api/v1/invitations/:id
  def show
  end

  # POST /api/v1/teams/:team_id/invitations
  def create
    @invitation.membership.team = current_team
    # this allows notifications to be sent to a user before they've accepted their invitation.
    @invitation.membership.user_email = @invitation.email
    @invitation.from_membership = current_membership
    if @invitation.save
      render :show, status: :created, location: [:api, :v1, @invitation]
    else
      render json: @invitation.errors, status: :unprocessable_entity
    end
  end

  # POST /api/v1/invitations/1/resend
  def resend
    if @invitation.touch
      UserMailer.invited(params[:id]).deliver_later
      render :show, status: :ok, location: [:api, :v1, @invitation]
    else
      render json: @invitation.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/invitations/:id
  def destroy
    @invitation.destroy
  end
end
