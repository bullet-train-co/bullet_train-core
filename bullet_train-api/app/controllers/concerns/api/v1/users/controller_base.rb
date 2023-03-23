module Api::V1::Users::ControllerBase
  extend ActiveSupport::Concern

  module StrongParameters
    # Only allow a list of trusted parameters through.
    def user_params
      password_fields = [
        :password,
        :current_password,
        :password_confirmation
      ]
      general_fields = [
        :email,
        :first_name,
        :last_name,
        :time_zone,
        :locale
      ]

      selected_fields = if params.is_a?(BulletTrain::Api::StrongParametersReporter)
        password_fields + general_fields
      else
        (params["commit"] == t(".buttons.update_password")) ? password_fields : general_fields
      end

      strong_params = params.require(:user).permit(
        *permitted_fields,
        *selected_fields,
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

  # PUT /api/v1/users/:id
  # TODO: Implement this!
  def update
    raise "Not implemented"
  end
end
