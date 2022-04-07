module Api::V1::Base
  extend ActiveSupport::Concern

  included do
    include Api::V1::Defaults
    include Api::V1::LoadsAndAuthorizesApiResource
    include Api::V1::ExceptionsHandler

    version "v1"

    use ::WineBouncer::OAuth2, message: "Doorkeeper OAuth2 Authentication"

    rescue_from :all do |error|
      handle_api_error(error)
    end

    BulletTrain::Api.endpoints.each do |endpoint_class|
      mount endpoint_class.constantize
    end

    after_validation do
      # Ensure responses never get cached.
      header "Cache-Control", "no-store"
    end
  end

  class_methods do
    # TODO I actually don't know of any way to make this work. This was supposed to be run after all other endpoints
    # are registered, but I don't know of a way to know when we're done running `initializer` blocks from the engines
    # a user may have included.
    def handle_not_found
      route :any, "*path" do
        raise StandardError, "Unable to find API endpoint"
      end
    end
  end
end
