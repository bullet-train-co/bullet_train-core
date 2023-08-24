module Api::V1::Memberships::ControllerBase
  extend ActiveSupport::Concern

  module StrongParameters
    # Only allow a list of trusted parameters through.
    def membership_params
      strong_params = params.require(:membership).permit(
        *permitted_fields,
        :user_first_name,
        :user_last_name,
        # 🚅 super scaffolding will insert new fields above this line.
        *permitted_arrays,
        # 🚅 super scaffolding will insert new arrays above this line
      )

      process_params(strong_params)

      strong_params
    end
  end

  included do
    load_and_authorize_resource :membership, class: "Membership", prepend: true,
      member_actions: (defined?(MEMBER_ACTIONS) ? MEMBER_ACTIONS : []),
      collection_actions: (defined?(COLLECTION_ACTIONS) ? COLLECTION_ACTIONS : [])

    private

    include StrongParameters
  end

  # GET /api/v1/teams/:team_id/memberships
  def index
  end

  # GET /api/v1/memberships/:id
  def show
  end

  # POST /api/v1/teams/:team_id/memberships
  def create
    if @membership.save
      render :show, status: :created, location: [:api, :v1, @membership]
    else
      render json: @membership.errors, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/memberships/:id
  def update
    if @membership.update(membership_params)
      render :show
    else
      render json: @membership.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/memberships/:id
  def destroy
    @membership.destroy
  end
end
