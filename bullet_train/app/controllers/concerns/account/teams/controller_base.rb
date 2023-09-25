module Account::Teams::ControllerBase
  extend ActiveSupport::Concern
  extend Controllers::Base

  included do
    load_and_authorize_resource :team, class: "Team", prepend: true,
      member_actions: (defined?(MEMBER_ACTIONS) ? MEMBER_ACTIONS : []),
      collection_actions: (defined?(COLLECTION_ACTIONS) ? COLLECTION_ACTIONS : [])

    prepend_before_action do
      if params["action"] == "new"
        current_user&.current_team = nil
      end
    end

    before_action :enforce_invitation_only, only: [:create]

    before_action do
      # for magic locales.
      @child_object = @team
    end

    private

    if defined?(Api::V1::ApplicationController)
      include strong_parameters_from_api
    end
  end

  # GET /teams
  # GET /teams.json
  def index
    # if a user doesn't have multiple teams, we try to simplify the team ui/ux
    # as much as possible. links to this page should go to the current team
    # dashboard. however, some other links to this page are actually in branch
    # logic and will not display at all. instead, users will be linked to the
    # "new team" page. (see the main account sidebar menu for an example of
    # this.)
    unless current_user.multiple_teams?
      redirect_to account_team_path(current_team)
    end
  end

  # POST /teams/1/switch
  def switch_to
    current_user.current_team = @team
    current_user.save
    redirect_to account_dashboard_path
  end

  # GET /teams/1
  # GET /teams/1.json
  def show
    # I don't think this is the best place to close the loop on the onboarding process, but practically speaking it's
    # the easiest place to implement this at the moment, because all the onboarding steps redirect here on success.
    if session[:after_onboarding_url].present?
      redirect_to session.delete(:after_onboarding_url)
    end

    current_user.current_team = @team
    current_user.save
  end

  # GET /teams/new
  def new
    render :new, layout: "devise"
  end

  # GET /teams/1/edit
  def edit
  end

  # POST /teams
  # POST /teams.json
  def create
    @team = Team.new(team_params)

    respond_to do |format|
      if @team.save

        # also make the creator of the team the default admin.
        @team.memberships.create(user: current_user, roles: [Role.admin])

        current_user.current_team = @team
        current_user.former_user = false
        current_user.save

        format.html { redirect_to [:account, @team], notice: I18n.t("teams.notifications.created") }
        format.json { render :show, status: :created, location: [:account, @team] }
      else
        format.html { render :new, layout: "devise", status: :unprocessable_entity }
        format.json { render json: @team.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /teams/1
  # PATCH/PUT /teams/1.json
  def update
    respond_to do |format|
      if @team.update(team_params)
        format.html { redirect_to [:account, @team], notice: I18n.t("teams.notifications.updated") }
        format.json { render :show, status: :ok, location: [:account, @team] }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @team.errors, status: :unprocessable_entity }
      end
    end
  end

  # # DELETE /teams/1
  # # DELETE /teams/1.json
  def destroy
    respond_to do |format|
      raise RemovingLastTeamException if current_user.one_team?
      @team.destroy
      format.html { redirect_to account_teams_url, notice: t("account.teams.notifications.destroyed") }
      format.json { head :no_content }
    rescue RemovingLastTeamException => _
      format.html { redirect_to edit_account_team_url(@team), alert: t("account.teams.notifications.cannot_delete_last_team") }
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
end
