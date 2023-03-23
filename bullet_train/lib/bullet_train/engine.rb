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
  end
end
