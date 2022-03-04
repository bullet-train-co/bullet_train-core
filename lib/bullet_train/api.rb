require "bullet_train/api/version"
require "bullet_train/api/engine"

require "grape"
require "grape-cancan"
require "grape_jsonapi"
require "grape-swagger"
require "grape_on_rails_routes"
# require "wine_bouncer"
require "kaminari"
require "api-pagination"
require "rack/cors"
require "jsonapi/serializer"
require "doorkeeper"

module BulletTrain
  module Api
    mattr_accessor :endpoints, default: []
  end
end
