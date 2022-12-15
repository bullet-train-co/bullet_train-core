module Api::V1::Teams::ControllerBase
  extend ActiveSupport::Concern

  module StrongParameters
    # Only allow a list of trusted parameters through.
    def team_params
      strong_params = params.require(:team).permit(
        *permitted_fields,
        :name,
        :time_zone,
        :locale,
        # 🚅 super scaffolding will insert new fields above this line.
        *permitted_arrays,
        # 🚅 super scaffolding will insert new arrays above this line.
      )

      process_params(strong_params)

      strong_params
    end
  end

  included do
    load_and_authorize_resource :team, class: "Team", prepend: true,
      member_actions: (defined?(MEMBER_ACTIONS) ? MEMBER_ACTIONS : []),
      collection_actions: (defined?(COLLECTION_ACTIONS) ? COLLECTION_ACTIONS : [])

    private

    include StrongParameters
  end

  # GET /api/v1/teams
  def index
  end

  # GET /api/v1/teams/:id
  def show
  end

  # PATCH/PUT /api/v1/teams/:id
  def update
    if @team.update(team_params)
      render :show
    else
      render json: @team.errors, status: :unprocessable_entity
    end
  end
end
