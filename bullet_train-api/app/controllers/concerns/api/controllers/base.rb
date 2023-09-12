require "pagy_cursor/pagy/extras/cursor"
require "pagy_cursor/pagy/extras/uuid_cursor"

module Api::Controllers::Base
  extend ActiveSupport::Concern

  # We need this to show custom error that user is not authenticated
  # neither with Doorkeeper nor with Devise
  class NotAuthenticatedError < StandardError; end

  included do
    include ActionController::Helpers
    helper ApplicationHelper

    include LoadsAndAuthorizesResource
    include Pagy::Backend

    before_action :set_default_response_format
    after_action :set_pagination_headers

    def modify_url_params(url, new_params)
      uri = URI.parse(url)
      query = Rack::Utils.parse_query(uri.query)
      new_params.each do |key, value|
        query[key.to_s] = value
      end
      uri.query = Rack::Utils.build_query(query)
      uri.to_s
    end

    def set_pagination_headers
      return unless @pagy

      if @pagy.has_more?
        if (collection = instance_variable_get(collection_variable))
          next_cursor = collection.last.id
          link_header = response.headers["Link"]
          link_value = "<#{modify_url_params(request.url, after: next_cursor)}>; rel=\"next\""
          response.headers["Link"] = link_header ? "#{link_header}, #{link_value}" : link_value
          response.headers["Pagination-Next"] = next_cursor
        end
      end
    end

    rescue_from CanCan::AccessDenied, ActiveRecord::RecordNotFound do |exception|
      render json: {error: "Not found"}, status: :not_found
    end

    rescue_from NotAuthenticatedError do |exception|
      render json: {error: "Invalid token or no user signed in"}, status: :unauthorized
    end

    before_action :apply_pagination, only: [:index]
  end

  def permitted_fields
    []
  end

  def permitted_arrays
    {}
  end

  def process_params(strong_params)
  end

  def current_user
    @current_user ||= if doorkeeper_token
      User.find_by(id: doorkeeper_token[:resource_owner_id])
    else
      warden.authenticate(scope: :user)
    end

    # TODO Remove this rescue once workspace clusters can write to this column on the identity server.
    if doorkeeper_token
      begin
        doorkeeper_token.update(last_used_at: Time.zone.now)
      rescue ActiveRecord::StatementInvalid => _
      end
    end

    raise NotAuthenticatedError unless @current_user

    @current_user
  end

  def current_team
    # Application agents are users but only have one team.
    current_user&.teams&.first
  end

  def current_membership
    current_user.memberships.where(team: current_team).first
  end

  def collection_variable
    @collection_variable ||= "@#{self.class.name.split("::").last.gsub("Controller", "").underscore}"
  end

  def apply_pagination
    collection = instance_variable_get collection_variable
    @pagy, collection = pagy_cursor collection, after: params[:after], order: {id: :asc}
    instance_variable_set collection_variable, collection
  end

  def set_default_response_format
    request.format = :json
  end

  class_methods do
    def controller_namespace
      name.split("::").first(2).join("::")
    end

    def regex_to_remove_controller_namespace
      /^#{controller_namespace + "::"}/
    end
  end
end
