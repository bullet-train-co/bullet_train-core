# TODO Is there a better way to implement this?
# This monkey patch is required to ensure the OAuth2 token includes which team was connected to.
# It gets required by BulletTrain::Api.set_configuration.

class Doorkeeper::TokensController
  def create
    headers.merge!(authorize_response.headers)

    user = if authorize_response.is_a?(Doorkeeper::OAuth::ErrorResponse)
      nil
    else
      User.find(authorize_response.token.resource_owner_id)
    end

    # Add the selected `team_id` to this response.
    render json: authorize_response.body.merge(user&.teams&.one? ? {"team_id" => user.team_ids.first} : {}),
      status: authorize_response.status
  rescue Doorkeeper::Errors::DoorkeeperError => e
    handle_token_exception(e)
  end
end
