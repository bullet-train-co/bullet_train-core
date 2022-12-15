class SessionsController < Devise::SessionsController
  include Sessions::ControllerBase

  # If user_return_to points to an oauth path we disable Turbo on the sign in form.
  # This makes it work when we need to redirect to external sites and/or custom protocols.
  # With Turbo enabled the browser will block those redirects with a CORS error.
  # https://github.com/bullet-train-co/bullet_train/issues/384
  def user_return_to_is_oauth
    session["user_return_to"]&.match(/^\/oauth/)
  end
  helper_method :user_return_to_is_oauth

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
end
