require "bullet_train/api/version"
require "bullet_train/api/engine"
require "bullet_train/api/strong_parameters_reporter"

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
  end
end
