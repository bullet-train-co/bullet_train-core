module Controllers::Base
  extend ActiveSupport::Concern

  included do
    # these are common for authentication workflows.
    include InvitationOnlyHelper
    include InvitationsHelper

    include DeviseCurrentAttributes
    include Pagy::Backend

    around_action :set_locale
    layout :layout_by_resource

    before_action { @updating = request.headers["X-Cable-Ready"] == "update" }

    # TODO Extract this into an optional `bullet_train-sentry` package.
    before_action :set_sentry_context

    skip_before_action :verify_authenticity_token, if: -> { controller_name == "sessions" && action_name == "create" }

    rescue_from CanCan::AccessDenied do |exception|
      if current_user.nil?
        respond_to do |format|
          format.html do
            session["user_return_to"] = request.path
            redirect_to [:new, :user, :session], alert: exception.message
          end
        end
      elsif current_user.teams.none?
        respond_to do |format|
          format.html { redirect_to [:new, :account, :team], alert: exception.message }
        end
      else
        respond_to do |format|
          format.html { redirect_to account_teams_url, alert: exception.message }
        end
      end
    end
  end

  class_methods do
    def strong_parameters_from_api
      (name.gsub(regex_to_remove_controller_namespace, "Api::#{BulletTrain::Api.current_version.upcase}::") + "::StrongParameters").constantize
    end
  end

  # this is an ugly hack, but it's what is recommended at
  # https://github.com/plataformatec/devise/wiki/How-To:-Create-custom-layouts
  def layout_by_resource
    if devise_controller?
      "devise"
    else
      "public"
    end
  end

  def after_sign_in_path_for(resource_or_scope)
    resource = resource_or_scope.class.name.downcase
    stored_location_for(resource) || account_dashboard_path
  end

  def after_sign_up_path_for(resource_or_scope)
    resource = resource_or_scope.class.name.downcase
    stored_location_for(resource) || account_dashboard_path
  end

  def current_team
    helpers.current_team
  end

  def current_membership
    helpers.current_membership
  end

  def current_locale
    helpers.current_locale
  end

  def enforce_invitation_only
    if invitation_only?
      unless helpers.invited?
        redirect_to [:account, :teams], notice: t("teams.notifications.invitation_only")
      end
    end
  end

  def set_locale(&action)
    locale = [
      current_user&.locale,
      current_user&.current_team&.locale,
      http_accept_language.compatible_language_from(I18n.available_locales),
      I18n.default_locale.to_s
    ].compact.find { |potential_locale| I18n.available_locales.include?(potential_locale.to_sym) }
    I18n.with_locale(locale, &action)
  end

  # Whitelist the account namespace and prevent JavaScript
  # embedding when passing paths as parameters in links.
  def only_allow_path(path)
    return if path.nil?
    account_namespace_regexp = /^\/account\/*+/
    scheme = URI.parse(path).scheme
    return nil unless path.match?(account_namespace_regexp) && scheme != "javascript"
    path
  end

  # TODO Extract this into an optional `bullet_train-sentry` package.
  def set_sentry_context
    return unless ENV["SENTRY_DSN"]

    Sentry.configure_scope do |scope|
      scope.set_user(id: current_user.id, email: current_user.email) if current_user

      scope.set_context(
        "request",
        {
          url: request.url,
          params: params.to_unsafe_h
        }
      )
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

  def delegate_json_to_api(&block)
    respond_to do |format|
      format.html(&block)
      format.json { render "#{params[:controller].gsub(/^account\//, "api/#{BulletTrain::Api.current_version}/")}/#{params[:action]}" }
    end
  end
end
