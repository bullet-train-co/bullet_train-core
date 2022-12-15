module Api::V1::Users::ControllerBase
  extend ActiveSupport::Concern

  module StrongParameters
    # Only allow a list of trusted parameters through.
    def user_params
      strong_params = params.require(:user).permit(
        *permitted_fields,
        :email,
        :first_name,
        :last_name,
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
    load_and_authorize_resource :user, class: "User", prepend: true,
      member_actions: (defined?(MEMBER_ACTIONS) ? MEMBER_ACTIONS : []),
      collection_actions: (defined?(COLLECTION_ACTIONS) ? COLLECTION_ACTIONS : [])

    private

    include StrongParameters
  end

  # GET /api/v1/users
  def index
  end

  # GET /api/v1/users/:id
  def show
  end
end
