require "pagy_cursor/pagy/extras/cursor"
require "pagy_cursor/pagy/extras/uuid_cursor"

module Api::Controllers::Base
  extend ActiveSupport::Concern

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
    raise Doorkeeper::Errors::InvalidToken unless doorkeeper_token.present?
    # TODO Remove this rescue once workspace clusters can write to this column on the identity server.
    # TODO Make this logic configurable so that downstream developers can write different methods for this column getting updated.
    begin
      doorkeeper_token.update(last_used_at: Time.zone.now)
    rescue ActiveRecord::StatementInvalid => _
    end
    @current_user ||= User.find_by(id: doorkeeper_token[:resource_owner_id])
  end

  def current_team
    # Application agents are users but only have one team.
    current_user&.teams&.first
  end

  def collection_variable
    @collection_variable ||= "@#{self.class.name.split("::").last.gsub("Controller", "").underscore}"
  end

  def apply_pagination
    collection = instance_variable_get collection_variable
    @pagy, collection = pagy_cursor collection, after: params[:after]
    instance_variable_set collection_variable, collection
  end

  def set_default_response_format
    request.format = :json
  end

  class_methods do
    def regex_to_remove_controller_namespace
      /^#{name.split("::").first(2).join("::") + "::"}/
    end
  end
end
