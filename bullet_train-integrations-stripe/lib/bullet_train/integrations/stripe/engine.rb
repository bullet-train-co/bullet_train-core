module BulletTrain
  module Integrations
    module Stripe
      class Engine < ::Rails::Engine
        initializer "bullet_train.integrations.stripe.register_template_path" do |app|
          # Register the base path of this package with the Super Scaffolding engine.
          BulletTrain::SuperScaffolding.template_paths << File.expand_path("../../../../..", __FILE__)
        end
      end
    end
  end
end
