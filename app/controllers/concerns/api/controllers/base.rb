require "pagy_cursor/pagy/extras/cursor"
require "pagy_cursor/pagy/extras/uuid_cursor"

module Api::Controllers::Base
  extend ActiveSupport::Concern

  # TODO Why doesn't `before_action :doorkeeper_authorize!` throw an exception?
  class NotAuthenticatedError < StandardError
  end

  included do
    include ActionController::Helpers
    helper ApplicationHelper

    include LoadsAndAuthorizesResource
    include Pagy::Backend

    before_action :set_default_response_format
    before_action :doorkeeper_authorize!

    rescue_from CanCan::AccessDenied, ActiveRecord::RecordNotFound do |exception|
      render json: {error: "Not found"}, status: :not_found
    end

    rescue_from NotAuthenticatedError do |exception|
      render json: {error: "Invalid token"}, status: :unauthorized
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
    raise NotAuthenticatedError unless doorkeeper_token.present?
    doorkeeper_token.update(last_used_at: Time.zone.now)
    @current_user ||= User.find_by(id: doorkeeper_token[:resource_owner_id])
  end

  def current_team
    # Application agents are users but only have one team.
    current_user&.teams&.first
  end

  def apply_pagination
    collection_variable = "@#{self.class.name.split("::").last.gsub("Controller", "").underscore}"
    collection = instance_variable_get collection_variable
    @pagy, collection = pagy_cursor collection
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
