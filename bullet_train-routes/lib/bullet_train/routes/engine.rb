module BulletTrain
  module Routes
    class Engine < ::Rails::Engine
      # Routes are drawn by the `routes_reloader` in Rails' finisher, after every
      # initializer has run, so installing here guarantees `model` exists in
      # `config/routes.rb` without depending on Action Controller being loaded first.
      initializer "bullet_train.routes.install" do
        BulletTrain::Routes.install
      end
    end
  end
end
