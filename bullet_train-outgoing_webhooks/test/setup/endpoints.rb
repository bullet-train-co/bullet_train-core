# Workaround to set variables instead of account_load_and_authorize_resource
module EndpointsControllerHooks
  def index
    @endpoints = Team.first.webhooks_outgoing_endpoints
    super
  end

  def show
    @endpoint = Team.first.webhooks_outgoing_endpoints.find(params[:id])
    super
  end

  def create
    @endpoint = Team.first.webhooks_outgoing_endpoints.new(endpoint_params)
    super
  end

  def update
    @endpoint = Team.first.webhooks_outgoing_endpoints.find(params[:id])
    super
  end

  def destroy
    @endpoint = Team.first.webhooks_outgoing_endpoints.find(params[:id])
    super
  end

  def activate
    @endpoint = Team.first.webhooks_outgoing_endpoints.find(params[:id])
    super
  end

  def deactivate
    @endpoint = Team.first.webhooks_outgoing_endpoints.find(params[:id])
    super
  end
end

Api::V1::Webhooks::Outgoing::EndpointsController.prepend EndpointsControllerHooks
