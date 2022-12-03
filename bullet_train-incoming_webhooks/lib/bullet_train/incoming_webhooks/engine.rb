require "bullet_train/incoming_webhooks/scaffolders/incoming_webhooks_scaffolder"
require "bullet_train/super_scaffolding"

module BulletTrain
  module IncomingWebhooks
    class Engine < ::Rails::Engine
      initializer "bullet_train.super_scaffolding.incoming_webhooks.templates.register_template_path" do |app|
        # Register the base of this package with the Super Scaffolding engine.
        BulletTrain::SuperScaffolding.template_paths << File.expand_path("../../../..", __FILE__)
        BulletTrain::SuperScaffolding.scaffolders.merge!({
          "incoming-webhooks" => "BulletTrain::IncomingWebhooks::Scaffolders::IncomingWebhooksScaffolder"
        })
      end
    end
  end
end
