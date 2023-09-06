module Sessions::ControllerBase
  extend ActiveSupport::Concern

  # If user_return_to points to an oauth path we disable Turbo on the sign in form.
  # This makes it work when we need to redirect to external sites and/or custom protocols.
  # With Turbo enabled the browser will block those redirects with a CORS error.
  # https://github.com/bullet-train-co/bullet_train/issues/384
  def user_return_to_is_oauth
    session["user_return_to"]&.match(/^\/oauth/)
  end

  included do
    helper_method :user_return_to_is_oauth
  end

  def new
    # We allow people to pass in a URL to redirect to after sign in is complete. We have to do this because Safari
    # doesn't allow them to set this in a session before a redirect if there isn't already a session. However, for
    # security reasons we have to make sure we control the URL where we will redirect to, otherwise people could
    # trick folks into redirecting to a fake destination in a phishing scheme.
    if params[:return_url]&.start_with?(ENV["BASE_URL"])
      store_location_for(resource_name, params[:return_url])
    end

    super
  end

  def destroy
    if params.include?(:onboard_logout)
      signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
      set_flash_message! :notice, :signed_out if signed_out
      yield if block_given?
      redirect_to root_path
    else
      super
    end
  end

  def pre_otp
    if (@email = params["user"]["email"].downcase.strip.presence)
      @user = User.find_by(email: @email)
    end

    respond_to do |format|
      format.js
    end
  end
end
