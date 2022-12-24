class Api::V1::Webhooks::Outgoing::EventsController < Api::V1::ApplicationController
  account_load_and_authorize_resource :event, through: :team, through_association: :webhooks_outgoing_events

  # GET /api/v1/teams/:team_id/webhooks/outgoing/events
  def index
    render json: @events.map(&:payload)
  end

  # GET /api/v1/webhooks/outgoing/events/:id
  def show
    render json: @event.payload
  end

  private

  module StrongParameters
    # Only allow a list of trusted parameters through.
    def event_params
      strong_params = params.require(:webhooks_outgoing_event).permit(
        *permitted_fields,
        # 🚅 super scaffolding will insert new fields above this line.
        *permitted_arrays,
        # 🚅 super scaffolding will insert new arrays above this line.
      )

      process_params(strong_params)

      strong_params
    end
  end

  include StrongParameters
end
