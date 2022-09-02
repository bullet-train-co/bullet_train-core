require "bullet_train/api/version"
require "bullet_train/api/engine"

# require "wine_bouncer"
require "pagy"
require "pagy_cursor"
require "rack/cors"
require "doorkeeper"

module BulletTrain
  module Api
    mattr_accessor :endpoints, default: []
    mattr_accessor :current_version, default: "v1"
  end
end
