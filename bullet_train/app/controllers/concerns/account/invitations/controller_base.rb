module Account::Invitations::ControllerBase
  extend ActiveSupport::Concern

  included do
    # the 'accept' action isn't covered by cancancan, because simply having the
    # link is authorization enough to claim membership on a team. see `#accept`
    # for more information.
    account_load_and_authorize_resource :invitation, :team, except: [:show]

    # we skip the onboarding requirement for users claiming and invitation.
    # this way the invitation gets accepted after they complete the devise
    # workflow, but before they're prompted to complete their onboarding.
    skip_before_action :ensure_onboarding_is_complete_and_set_next_step, only: :accept
    skip_before_action :authenticate_user!, only: :accept
  end

  # GET /invitations
  # GET /invitations.json
  def index
    redirect_to [:account, @team, :memberships]
  end

  # GET /invitations/1
  # GET /invitations/1.json
  def show
    # it's important that we only allow invitations to be shown via their uuid,
    # otherwise team members can just step the id in the url to claim an
    # invitation that would escalate their privileges.
    @invitation = Invitation.find_by(uuid: params[:id])
    unless @invitation
      raise I18n.t("global.notifications.not_found")
    end
    @team = @invitation.team

    # backfill these objects for the locale magic, since we didn't use `account_load_and_authorize_resource`.
    @child_object = @invitation
    @parent_object = @team

    render layout: "devise"
  end

  # POST /invitations/1/accept
  # POST /invitations/1/accept.json
  def accept
    # The user should be alerted when there is no
    # invitation regardless if they're registered or not.
    @invitation = Invitation.find_by(uuid: params[:id])
    flash[:alert] = t("invitations.notifications.doesnt_exist") if @invitation.nil?

    # unless the user is signed in.
    if !current_user.present?
      # We need them to register.
      # We have to send `invitation_uuid` via params, not session, because Safari doesn't set cookies on redirect.
      redirect_to new_user_registration_path(invitation_uuid: @invitation&.uuid)

    # session[:invitation_uuid] should only be present if the user is registering for the first time.
    elsif (@invitation = Invitation.find_by(uuid: session[:invitation_uuid] || params[:id]))
      session.delete(:invitation_uuid) if session[:invitation_uuid].present?

      if @invitation
        @team = @invitation.team
        if @invitation.is_for?(current_user) || request.post?
          @invitation.accept_for(current_user)
          redirect_to account_dashboard_path, notice: I18n.t("invitations.notifications.welcome", team_name: @team.name)
        else
          redirect_to account_invitation_path(@invitation.uuid)
        end
      else
        redirect_to account_invitation_path(@invitation.uuid)
      end
    else
      redirect_to account_dashboard_path
    end
  end

  # POST /invitations/1/resend
  def resend
    @invitation = Invitation.find_by(uuid: params[:id])
    if @invitation&.touch
      UserMailer.invited(params[:id]).deliver_later
      redirect_to account_team_invitations_path(@invitation.membership.team), notice: I18n.t("invitations.notifications.resent")
    else
      redirect_to account_dashboard_path, alert: I18n.t("invitations.notifications.resent_error")
    end
  end

  # GET /invitations/new
  def new
    @invitation.build_membership
    @cancel_path = only_allow_path(params[:cancel_path])
  end

  # POST /invitations
  # POST /invitations.json
  def create
    @invitation.membership.team = current_team
    # this allows notifications to be sent to a user before they've accepted their invitation.
    @invitation.membership.user_email = @invitation.email
    @invitation.from_membership = current_membership
    respond_to do |format|
      if @invitation.save
        format.html { redirect_to account_team_invitations_path(@team), notice: I18n.t("invitations.notifications.created") }
        format.json { render :show, status: :created, location: [:account, @team, @invitation] }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @invitation.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /invitations/1
  # DELETE /invitations/1.json
  def destroy
    @invitation.destroy
    respond_to do |format|
      format.html { redirect_to account_team_invitations_path(@team), notice: I18n.t("invitations.notifications.destroyed") }
      format.json { head :no_content }
    end
  end

  private

  def permitted_fields
    raise "It looks like you've removed `permitted_fields` from your controller. This will break Super Scaffolding."
  end

  def permitted_arrays
    raise "It looks like you've removed `permitted_arrays` from your controller. This will break Super Scaffolding."
  end

  def process_params(strong_params)
    raise "It looks like you've removed `process_params` from your controller. This will break Super Scaffolding."
  end

  def manageable_role_keys
    helpers.current_membership.manageable_roles.map(&:key)
  end

  # NOTE this method is only designed to work in the context of creating a invitation.
  # we don't provide any support for updating invitations.
  def invitation_params
    # we use strong params first.
    strong_params = params.require(:invitation).permit(
      :email,
      # 🚅 super scaffolding will insert new fields above this line.
      # 🚅 super scaffolding will insert new arrays above this line.
      membership_attributes: [
        :user_first_name,
        :user_last_name,
        role_ids: []
      ],
    )

    # after that, we have to be more careful how we assign the roles.
    # we can't let users assign roles to an invitation that they don't have permission
    # to assign, but they do have permission to assign some to other team members.
    if params[:invitation] && params[:invitation][:role_ids].present?

      # ensure the list of role keys from the form only includes keys that they're allowed to assign.
      assignable_role_keys_from_the_form = params[:invitation][:role_ids].map(&:to_i) & manageable_role_keys

      strong_params[:role_ids] = assignable_role_keys_from_the_form

    end

    strong_params
  end
end
