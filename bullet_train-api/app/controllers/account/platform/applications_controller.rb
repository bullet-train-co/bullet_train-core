class Account::Platform::ApplicationsController < Account::ApplicationController
  account_load_and_authorize_resource :application, through: :team, through_association: :platform_applications

  # GET /account/teams/:team_id/platform/applications
  # GET /account/teams/:team_id/platform/applications.json
  def index
    # if you only want these objects shown on their parent's show page, uncomment this:
    # redirect_to [:account, @team]
  end

  # GET /account/platform/applications/:id
  # GET /account/platform/applications/:id.json
  def show
  end

  # GET /account/teams/:team_id/platform/applications/new
  def new
  end

  # GET /account/platform/applications/:id/edit
  def edit
  end

  def provision
    if ENV["TESTING_PROVISION_KEY"].present? && params[:key] == ENV["TESTING_PROVISION_KEY"]
      user = User.create(email: "test@#{SecureRandom.hex}.example.com", password: (password = SecureRandom.hex), password_confirmation: password)
      provision_team = current_user.teams.create(name: "provision-team-#{SecureRandom.hex}", time_zone: user.time_zone)
      test_application = Platform::Application.new(name: "test-application-#{SecureRandom.hex}", team: provision_team)

      if test_application.save
        access_token = test_application.create_access_token
        render json: {message: I18n.t("platform/applications.notifications.test_application_created"), team_id: provision_team.id, access_token: access_token.token}
      else
        render json: {errors: test_application.errors, status: :unprocessable_entity}
      end
    else
      render json: {message: I18n.t("platform/applications.notifications.test_application_failure")}
    end
  end

  # POST /account/teams/:team_id/platform/applications
  # POST /account/teams/:team_id/platform/applications.json
  def create
    respond_to do |format|
      if @application.save
        format.html { redirect_to [:account, @application], notice: I18n.t("platform/applications.notifications.created") }
        format.json { render :show, status: :created, location: [:account, @application] }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @application.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /account/platform/applications/:id
  # PATCH/PUT /account/platform/applications/:id.json
  def update
    respond_to do |format|
      if @application.update(application_params)
        format.html { redirect_to [:account, @application], notice: I18n.t("platform/applications.notifications.updated") }
        format.json { render :show, status: :ok, location: [:account, @application] }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @application.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /account/platform/applications/:id
  # DELETE /account/platform/applications/:id.json
  def destroy
    @application.destroy
    respond_to do |format|
      format.html { redirect_to [:account, @team, :platform_applications], notice: I18n.t("platform/applications.notifications.destroyed") }
      format.json { head :no_content }
    end
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def application_params
    params.require(:platform_application).permit(
      :name,
      :redirect_uri,
      # 🚅 super scaffolding will insert new fields above this line.
      # 🚅 super scaffolding will insert new arrays above this line.
    )

    # 🚅 super scaffolding will insert processing for new fields above this line.
  end
end
