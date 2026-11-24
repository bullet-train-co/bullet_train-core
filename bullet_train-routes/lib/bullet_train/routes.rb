require "bullet_train/routes/version"
require "bullet_train/routes/mapper_extensions"

module BulletTrain
  module Routes
    # Makes `model` available in the routing DSL. Safe to call more than once.
    def self.install
      return false unless defined?(ActionDispatch::Routing::Mapper)
      return false if ActionDispatch::Routing::Mapper.include?(MapperExtensions)

      ActionDispatch::Routing::Mapper.include(MapperExtensions)
      true
    end
  end
end

# In a Rails app the engine installs the DSL from an initializer, which always runs before
# `config/routes.rb` is evaluated. Outside Rails (or if Action Pack is already loaded by the
# time this file is required) install it right away.
if defined?(Rails::Engine)
  require "bullet_train/routes/engine"
else
  BulletTrain::Routes.install
end
