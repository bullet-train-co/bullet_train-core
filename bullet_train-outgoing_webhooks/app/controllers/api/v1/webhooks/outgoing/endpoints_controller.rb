class Api::V1::Webhooks::Outgoing::EndpointsController < Api::V1::ApplicationController
  account_load_and_authorize_resource :endpoint,
    through: BulletTrain::OutgoingWebhooks.parent_association,
    through_association: :webhooks_outgoing_endpoints

  # GET /api/v1/teams/:team_id/webhooks/outgoing/endpoints
  def index
  end

  # GET /api/v1/webhooks/outgoing/endpoints/:id
  def show
  end

  # POST /api/v1/teams/:team_id/webhooks/outgoing/endpoints
  def create
    if @endpoint.save
      render :show, status: :created, location: [:api, :v1, @endpoint]
    else
      render json: @endpoint.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/webhooks/outgoing/endpoints/:id
  def update
    if @endpoint.update(endpoint_params)
      render :show
    else
      render json: @endpoint.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/webhooks/outgoing/endpoints/:id
  def destroy
    @endpoint.destroy
  end

  private

  module StrongParameters
    # Only allow a list of trusted parameters through.
    def endpoint_params
      strong_params = params.require(:webhooks_outgoing_endpoint).permit(
        *permitted_fields,
        :url,
        :name,
        :api_version,
        :scaffolding_absolutely_abstract_creative_concept_id,
        # 🚅 super scaffolding will insert new fields above this line.
        *permitted_arrays,
        event_type_ids: [],
        # 🚅 super scaffolding will insert new arrays above this line.
      )

      process_params(strong_params)

      strong_params
    end
  end

  include StrongParameters
end
