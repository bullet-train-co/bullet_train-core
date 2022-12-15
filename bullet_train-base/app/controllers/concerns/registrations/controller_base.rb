module Registrations::ControllerBase
  extend ActiveSupport::Concern

  included do
    def new
      # We have to set the session here because Safari wouldn't save it on a redirect to this URL.
      if params[:invitation_uuid]
        session[:invitation_uuid] = params[:invitation_uuid]
        session["user_return_to"] = accept_account_invitation_path(params[:invitation_uuid])
      end

      if invitation_only?
        unless session[:invitation_uuid] || session[:invitation_key]
          return redirect_to root_path
        end
      end

      # do all the regular devise stuff.
      super
    end

    def create
      # do all the regular devise stuff first.
      super

      # if current_user is defined, that means they were successful registering.
      if current_user
        # Don't create a default team if they're being invited to another team.
        # Don't create a default team if they have another one for any reason.
        unless session[:invitation_uuid].present? || current_user.teams.any?
          current_user.create_default_team
        end

        # send the welcome email.
        current_user.send_welcome_email unless current_user.email_is_oauth_placeholder?
      end
    end
  end
end
