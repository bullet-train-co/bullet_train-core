module BulletTrain
  module Api
    module Attributes
      # We default this to the current version of the API, but developers can request a specific version.
      def api_attributes(api_version = BulletTrain::Api.current_version_numeric)
        controller = "Api::V#{api_version}::ApplicationController".constantize.new
        # TODO We need to fix host names here.
        controller.request = ActionDispatch::Request.new({})
        local_class_key = self.class.name.underscore.split("/").last.to_sym

        # Returns a hash, not string.
        JbuilderTemplate.new(controller.view_context) do |json|
          json.partial! "api/#{BulletTrain::Api.current_version}/#{self.class.name.underscore.pluralize}/#{local_class_key}", local_class_key => self
        end.attributes!
      end
    end
  end
end
