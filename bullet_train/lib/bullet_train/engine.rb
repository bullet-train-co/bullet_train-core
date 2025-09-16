begin
  # We hoist the Devise engine, so its app/views directory is always after ours in a Rails app's view_paths.
  #
  # This is a quirk of how Rails engines compose, since engines `prepend_view_path` with their views:
  # https://github.com/rails/rails/blob/9f141a423d551f7f421f54d1372e65ef6ed1f0be/railties/lib/rails/engine.rb#L606
  #
  # If users put devise after bullet_train in their Gemfile, Bundler requires the gems in that order,
  # and devise's `prepend_view_path` would be called last, thus being prepended ahead of BulletTrain when Rails looks up views.
  #
  # Note: if this breaks down in the future, we may want to look into config.railties_order.
  require "devise"
rescue LoadError
  # Devise isn't in the Gemfile, and we don't have any other load order dependencies.
end

begin
  # Similarly we need to hoist showcase-rails, so our view paths can override Showcase.
  require "showcase-rails"
rescue LoadError
end

module BulletTrain
  class Engine < ::Rails::Engine
    initializer "bullet_train.importmap", before: "importmap" do |app|
      # NOTE: this will add pins from this engine to the main app
      # https://github.com/rails/importmap-rails#composing-import-maps
      app.config.importmap.paths << BulletTrain::Engine.root.join("config/importmap.rb")

      # https://github.com/rails/importmap-rails#sweeping-the-cache-in-development-and-test
      app.config.importmap.cache_sweepers << BulletTrain::Engine.root.join("app/javascript")
    end
    initializer "bullet_train.assets" do
      if Rails.application.config.respond_to?(:assets)
        Rails.application.config.assets.paths << BulletTrain::Engine.root.join("app/javascript")
        #Rails.application.config.assets.precompile += PRECOMPILE_ASSETS
      end
    end
  end
end
