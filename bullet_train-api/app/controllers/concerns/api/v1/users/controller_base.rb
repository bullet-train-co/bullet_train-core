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
        :current_password,
        :password,
        :password_confirmation,
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

    prepend_before_action :resolve_me

    private

    include StrongParameters
  end

  # GET /api/v1/users
  def index
  end

  def resolve_me
    if current_user && params[:id]&.downcase == "me"
      params[:id] = current_user.id
    end
  end

  # GET /api/v1/users/:id
  def show
  end
end
