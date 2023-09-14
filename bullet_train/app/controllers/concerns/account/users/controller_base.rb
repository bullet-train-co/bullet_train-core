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

    private

    include strong_parameters_from_api
  end

  # GET /account/users/1/edit
  def edit
  end

  # GET /account/users/1
  def show
  end

  def updating_password_or_email?
    params[:user].key?(:password) || params[:user].key?(:email)
  end

  # TODO: We're keeping this method for backward compatibility in case someone in a downstream app
  # might be using it. At some point in the future (unclear exactly when) we should remove it.
  def updating_password?
    ActiveSupport::Deprecation.warn(
      "#updating_password? is deprecated. " \
      "Use #updating_password_or_email? instead."
    )
    params[:user].key?(:password)
  end

  # PATCH/PUT /account/users/1
  # PATCH/PUT /account/users/1.json
  def update
    respond_to do |format|
      if updating_password_or_email? ? @user.update_with_password(user_params) : @user.update_without_password(user_params)
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
end
