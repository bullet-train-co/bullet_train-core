class SessionsController < Devise::SessionsController
  include Sessions::ControllerBase

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
