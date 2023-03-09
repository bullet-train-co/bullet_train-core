class Api::V1::Webhooks::Outgoing::EventsController < Api::V1::ApplicationController
  account_load_and_authorize_resource :event,
    through: BulletTrain::OutgoingWebhooks.parent_association,
    through_association: :webhooks_outgoing_events

  # GET /api/v1/teams/:team_id/webhooks/outgoing/events
  def index
    render json: @events.map(&:payload)
  end

  # GET /api/v1/webhooks/outgoing/events/:id
  def show
    render json: @event.payload
  end
end
