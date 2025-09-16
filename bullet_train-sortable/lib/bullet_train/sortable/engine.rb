module BulletTrain
  module Sortable
    class Engine < ::Rails::Engine
      initializer "bullet_train.sortable.importmap", before: "importmap" do |app|
        # NOTE: this will add pins from this engine to the main app
        # https://github.com/rails/importmap-rails#composing-import-maps
        app.config.importmap.paths << BulletTrain::Sortable::Engine.root.join("config/importmap.rb")

        # https://github.com/rails/importmap-rails#sweeping-the-cache-in-development-and-test
        app.config.importmap.cache_sweepers << BulletTrain::Sortable::Engine.root.join("app/javascript")
      end
      initializer "bullet_train.sortable.assets" do
        if Rails.application.config.respond_to?(:assets)
          Rails.application.config.assets.paths << BulletTrain::Sortable::Engine.root.join("app/javascript")
          #Rails.application.config.assets.precompile += PRECOMPILE_ASSETS
        end
      end
      initializer "bullet_train.sortable.register_routing_concerns" do |app|
        BulletTrain.routing_concerns << proc do
          concern :sortable do
            collection do
              post :reorder
            end
          end
        end
      end
    end
  end
end
