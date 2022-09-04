module Account::Users::ControllerBase
  extend ActiveSupport::Concern

  included do
    load_and_authorize_resource :user, class: "User", prepend: true,
      member_actions: (defined?(MEMBER_ACTIONS) ? MEMBER_ACTIONS : []),
      collection_actions: (defined?(COLLECTION_ACTIONS) ? COLLECTION_ACTIONS : [])

    before_action do
      # for magic locales.
      @child_object = @user
    end
  end

  # GET /account/users/1/edit
  def edit
  end

  # GET /account/users/1
  def show
  end

  def updating_password?
    params[:user].key?(:password)
  end

  # PATCH/PUT /account/users/1
  # PATCH/PUT /account/users/1.json
  def update
    respond_to do |format|
      if updating_password? ? @user.update_with_password(user_params) : @user.update_without_password(user_params)
        # if you update your own user account, devise will normally kick you out, so we do this instead.
        bypass_sign_in current_user.reload
        format.html { redirect_to [:edit, :account, @user], notice: t("users.notifications.updated") }
        format.json { render :show, status: :ok, location: [:account, @user] }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def permitted_fields
    raise "It looks like you've removed `permitted_fields` from your controller. This will break Super Scaffolding."
  end

  def permitted_arrays
    raise "It looks like you've removed `permitted_arrays` from your controller. This will break Super Scaffolding."
  end

  def process_params(strong_params)
    raise "It looks like you've removed `process_params` from your controller. This will break Super Scaffolding."
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  # TODO Update this to use `include strong_parameters_from_api`.
  def user_params
    # TODO enforce permissions on updating the user's team name.
    strong_params = params.require(:user).permit(
      *([
        :email,
        :first_name,
        :last_name,
        :time_zone,
        :current_password,
        :password,
        :password_confirmation,
        :profile_photo_id,
        :locale,
      ] + permitted_fields + [
        {
          current_team_attributes: [:name]
        }.merge(permitted_arrays)
      ])
    )

    process_params(strong_params)
  end
end
