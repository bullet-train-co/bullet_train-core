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

    before_action :apply_filters, only: [:index]
    before_action :apply_pagination, only: [:index]

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
      if collection_has_more?
        link_header = response.headers["Link"]
        link_value = "<#{modify_url_params(request.url, after: last_id_in_collection)}>; rel=\"next\""
        response.headers["Link"] = link_header ? "#{link_header}, #{link_value}" : link_value
        response.headers["Pagination-Next"] = last_id_in_collection
      end
    end

    def collection_has_more?
      return false unless last_id_in_collection
      remaining_collection = collection.limit(nil).order(id: :asc).where("id > ?", last_id_in_collection)
      remaining_collection.any?
    end

    def last_id_in_collection
      @last_id_in_collection ||= collection&.last&.id
    end

    rescue_from CanCan::AccessDenied, ActiveRecord::RecordNotFound do |exception|
      render json: {error: "Not found"}, status: :not_found
    end

    rescue_from NotAuthenticatedError do |exception|
      render json: {error: "Invalid token or no user signed in"}, status: :unauthorized
    end
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

  def collection
    @collection ||= instance_variable_get(collection_variable)
  end

  def collection=(new_collection)
    @collection = new_collection
    instance_variable_set collection_variable, new_collection
  end

  def apply_filters
    # An empty method that descendant controllers can override
    # A possible implementaiton might look like:
    #
    # self.collection = collection.where(status: params[:filter_status]) if params[:filter_status]
  end

  def apply_pagination
    pagination_collection = collection.order(id: :asc)
    if params[:after]
      pagination_collection = pagination_collection.where("id > ?", params[:after])
    end
    @pagy, pagination_collection = pagy(pagination_collection)
    self.collection = pagination_collection
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
