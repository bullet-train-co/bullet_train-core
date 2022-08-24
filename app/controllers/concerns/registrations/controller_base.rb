module Registrations::ControllerBase
  extend ActiveSupport::Concern

  included do
    def new
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
        # if the user doesn't have a team at this point, create one.
        # If the user is accepting an invitation, then the user's current_team is populated
        # with the information attached to their invitation via `@invitation.accept_for` later on,
        # so we don't have to create a default team for them here.
        unless current_user.teams.any? || session[:invitation_uuid].present?
          current_user.create_default_team
        end

        # send the welcome email.
        current_user.send_welcome_email unless current_user.email_is_oauth_placeholder?

      end
    end
  end
end
