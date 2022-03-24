module Sessions::ControllerBase
  extend ActiveSupport::Concern

  included do
    # TODO I'm not sure why the sign-in page started throwing a `ActionController::InvalidAuthenticityToken`. I'm doing
    # this as a temporary workaround, but this shouldn't be here long-term.
    skip_before_action :verify_authenticity_token, only: [:create]
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
