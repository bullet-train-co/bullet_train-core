require "bullet_train/api/version"
require "bullet_train/api/engine"
require "bullet_train/api/strong_parameters_reporter"
require "bullet_train/api/example_bot"
require "bullet_train/platform/connection_workflow"

# require "wine_bouncer"
require "pagy"
require "pagy_cursor"
require "rack/cors"
require "doorkeeper"
require "scaffolding"
require "scaffolding/block_manipulator"
require "scaffolding/transformer"
require "jbuilder/schema"

module BulletTrain
  module Api
    mattr_accessor :endpoints, default: []
    mattr_accessor :current_version, default: "v1"
    mattr_accessor :initial_version, default: "v1"

    def self.current_version_numeric
      current_version.split("v").last.to_i
    end

    def self.initial_version_numeric
      initial_version.split("v").last.to_i
    end

    def self.all_versions
      (initial_version_numeric..current_version_numeric).map { |version| "v#{version}".to_sym }
    end

    def self.set_configuration(application_class)
      application_class.config.to_prepare do
        Doorkeeper::ApplicationController.layout "devise"

        if Doorkeeper::TokensController
          require_relative "../tokens_controller"
        end
      end
    end
  end
end
