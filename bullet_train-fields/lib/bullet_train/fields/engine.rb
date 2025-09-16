module BulletTrain
  module Fields
    class Engine < ::Rails::Engine
      initializer "bullet_train.fields.importmap", before: "importmap" do |app|
        # NOTE: this will add pins from this engine to the main app
        # https://github.com/rails/importmap-rails#composing-import-maps
        app.config.importmap.paths << BulletTrain::Fields::Engine.root.join("config/importmap.rb")

        # https://github.com/rails/importmap-rails#sweeping-the-cache-in-development-and-test
        app.config.importmap.cache_sweepers << BulletTrain::Fields::Engine.root.join("app/javascript")
      end
      initializer "bullet_train.fields.assets" do
        if Rails.application.config.respond_to?(:assets)
          Rails.application.config.assets.paths << BulletTrain::Fields::Engine.root.join("app/javascript")
          #Rails.application.config.assets.precompile += PRECOMPILE_ASSETS
        end
      end

      initializer "bullet_train.fields" do |app|
        # Older versions of Bullet Train have a `BulletTrain` module, but it doesn't have `linked_gems`.
        if BulletTrain.respond_to?(:linked_gems)
          BulletTrain.linked_gems << "bullet_train-fields"
        end
      end
    end
  end
end
