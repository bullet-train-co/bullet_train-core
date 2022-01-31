require "grape"
require "grape-cancan"
require "grape_jsonapi"
require "grape-swagger"
require "grape_on_rails_routes"
require "wine_bouncer"
require "kaminari"
require "api-pagination"
require "rack/cors"

module BulletTrain
  module Api
    class Engine < ::Rails::Engine
    end
  end
end
