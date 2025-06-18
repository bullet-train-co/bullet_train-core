class Account::Webhooks::Outgoing::EndpointsController < Account::ApplicationController
  account_load_and_authorize_resource :endpoint,
    through: BulletTrain::OutgoingWebhooks.parent_association,
    through_association: :webhooks_outgoing_endpoints,
    member_actions: [:activate, :deactivate]
  before_action { @parent = instance_variable_get("@#{BulletTrain::OutgoingWebhooks.parent_association}") }

  # GET /account/teams/:team_id/webhooks/outgoing/endpoints
  # GET /account/teams/:team_id/webhooks/outgoing/endpoints.json
  def index
    # if you only want these objects shown on their parent's show page, uncomment this:
    # redirect_to [:account, @team]
  end

  # GET /account/webhooks/outgoing/endpoints/:id
  # GET /account/webhooks/outgoing/endpoints/:id.json
  def show
  end

  # GET /account/teams/:team_id/webhooks/outgoing/endpoints/new
  def new
  end

  # GET /account/webhooks/outgoing/endpoints/:id/edit
  def edit
  end

  # POST /account/teams/:team_id/webhooks/outgoing/endpoints
  # POST /account/teams/:team_id/webhooks/outgoing/endpoints.json
  def create
    respond_to do |format|
      if @endpoint.save
        format.html { redirect_to [:account, @parent, :webhooks_outgoing_endpoints], notice: I18n.t("webhooks/outgoing/endpoints.notifications.created") }
        format.json { render :show, status: :created, location: [:account, @endpoint] }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @endpoint.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /account/webhooks/outgoing/endpoints/:id
  # PATCH/PUT /account/webhooks/outgoing/endpoints/:id.json
  def update
    respond_to do |format|
      if @endpoint.update(endpoint_params)
        format.html { redirect_to [:account, @endpoint], notice: I18n.t("webhooks/outgoing/endpoints.notifications.updated") }
        format.json { render :show, status: :ok, location: [:account, @endpoint] }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @endpoint.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /account/webhooks/outgoing/endpoints/:id
  # DELETE /account/webhooks/outgoing/endpoints/:id.json
  def destroy
    @endpoint.destroy
    respond_to do |format|
      format.html { redirect_to [:account, @parent, :webhooks_outgoing_endpoints], notice: I18n.t("webhooks/outgoing/endpoints.notifications.destroyed") }
      format.json { head :no_content }
    end
  end

  # POST /account/webhooks/outgoing/endpoints/:id/activate
  def activate
    respond_to do |format|
      if @endpoint.update(deactivated_at: nil, deactivation_limit_reached_at: nil, consecutive_failed_deliveries: 0)
        format.html { redirect_to [:account, @parent, :webhooks_outgoing_endpoints], notice: I18n.t("webhooks/outgoing/endpoints.notifications.activated") }
        format.json { render :show, status: :ok, location: [:account, @endpoint] }
      else
        format.html { redirect_to [:account, @parent, :webhooks_outgoing_endpoints], alert: I18n.t("webhooks/outgoing/endpoints.notifications.activation_failed") }
        format.json { render json: @endpoint.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /account/webhooks/outgoing/endpoints/:id/deactivate
  def deactivate
    respond_to do |format|
      if @endpoint.update(deactivated_at: Time.current)
        format.html { redirect_to [:account, @parent, :webhooks_outgoing_endpoints], notice: I18n.t("webhooks/outgoing/endpoints.notifications.deactivated") }
        format.json { render :show, status: :ok, location: [:account, @endpoint] }
      else
        format.html { redirect_to [:account, @parent, :webhooks_outgoing_endpoints], alert: I18n.t("webhooks/outgoing/endpoints.notifications.deactivation_failed") }
        format.json { render json: @endpoint.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def endpoint_params
    strong_params = params.require(:webhooks_outgoing_endpoint).permit(
      :name,
      :url,
      :scaffolding_absolutely_abstract_creative_concept_id,
      # 🚅 super scaffolding will insert new fields above this line.
      event_type_ids: [],
      # 🚅 super scaffolding will insert new arrays above this line.
    )

    assign_select_options(strong_params, :event_type_ids)
    # 🚅 super scaffolding will insert processing for new fields above this line.

    strong_params
  end
end
