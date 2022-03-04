require "grape"
require "grape-cancan"
require "grape_jsonapi"
require "grape-swagger"
require "grape_on_rails_routes"
# require "wine_bouncer"
require "kaminari"
require "api-pagination"
require "rack/cors"

module BulletTrain
  module Api
    class Engine < ::Rails::Engine
      initializer "bullet_train.api.register_api_endpoints" do |app|
        if BulletTrain::Api
          BulletTrain::Api.endpoints << "Api::V1::MeEndpoint"
          BulletTrain::Api.endpoints << "Api::V1::TeamsEndpoint"
        end
      end
    end
  end
end
