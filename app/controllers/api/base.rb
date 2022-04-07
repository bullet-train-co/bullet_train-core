require "grape-swagger"
require_relative "../api"

class Api::Base < Grape::API
  content_type :jsonapi, "application/vnd.api+json"
  formatter :json, Grape::Formatter::Jsonapi
  formatter :jsonapi, Grape::Formatter::Jsonapi
  format :jsonapi
  default_error_formatter :json

  mount Api::V1::Root

  # Swagger docs are available at `/api/docs/swagger.json`.
  add_swagger_documentation \
    api_version: "v1",
    array_use_braces: true,
    base_path: "/api",
    doc_version: "1.0",
    endpoint_auth_wrapper: ::WineBouncer::OAuth2,
    hide_documentation_path: true,
    info: {
      title: I18n.t("application.name"),
      description: I18n.t("application.description")
    },
    mount_path: "/docs/swagger"

  # TODO Reintroduce this once we've got `context` in current attributes.
  # before do
  #   Current.context = :api
  # end
end
