require "bullet_train/platform"

class BulletTrain::Platform::ConnectionWorkflow
  def to_proc
    proc do
      # Load the platform application in question.
      # TODO Do we need to check the client secret or does Doorkeeper do that for us?
      @application = Platform::Application.find_by(uid: params[:client_id])

      # If the user is current signed in.
      if current_user
        # If the client application is opting into a team-level connection instead of a user-level connection, they have
        # to select a team.
        if params[:new_installation]
          # If they selected a team on the team selection page.
          if params[:team_id]
            # Load the selected team.
            team = Team.find(params[:team_id])

            # Throw an error if they aren't allowed to create connections on this team.
            authorize! :connect, team

            # Create a faux membership and user that represent this connection.
            # We have to do this because all our permissions are based on users, so team-level connections need a user.
            faux_password = SecureRandom.hex
            faux_user = User.create(
              email: "noreply+#{SecureRandom.hex}@bullettrain.co",
              password: faux_password,
              password_confirmation: faux_password,
              platform_agent_of: @application,
              first_name: @application.name
            )

            faux_membership = team.memberships.create(
              user: faux_user,
              platform_agent: true,
              platform_agent_of: @application,
              added_by: team.memberships.find_by(user: current_user)
            )

            faux_membership.roles << Role.admin

            # We're done! Return the user, it'll be associated with the access grant and subsequent access token.
            faux_user
          else
            # Show them a list of all their teams.
            # We'll disable the teams they can't create connections for in the view.
            @teams = current_user.teams

            render "account/platform/connections/new"
          end
        else
          # If the client application isn't specifically opting into a team-level installation, just connect on behalf of the user.
          current_user
        end
      else
        # If they're not signed in, redirect them to the sign in page and set a return URL via params.
        # This is a crazy workaround for the fact that Safari doesn't let us create a session at the same time we redirect.
        redirect_to new_user_session_path(return_url: request.url)
      end
    end
  end
end
