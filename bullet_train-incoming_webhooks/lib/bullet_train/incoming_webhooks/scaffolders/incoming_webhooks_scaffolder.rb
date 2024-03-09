require "scaffolding/incoming_webhooks_transformer"
require "bullet_train/super_scaffolding/scaffolder"

module BulletTrain
  module IncomingWebhooks
    module Scaffolders
      class IncomingWebhooksScaffolder < SuperScaffolding::Scaffolder
        def run
          unless argv.count >= 1
            puts ""
            puts "🚅 usage: bin/super-scaffold incoming-webhooks SomeProvider"
            puts ""
            puts "E.g. prepare to receive system-level webhooks from ClickFunnels"
            puts "  bin/super-scaffold incoming-webhooks ClickFunnels"
            puts ""
            standard_protip
            puts ""
            return
          end

          provider_name = argv.shift
          transformer = Scaffolding::IncomingWebhooksTransformer.new(provider_name)

          `yes n | bin/rails g model Webhooks::Incoming::#{provider_name}Webhook data:jsonb processed_at:datetime verified_at:datetime`

          transformer.scaffold_incoming_webhook

          puts ""
          puts "1. To receive webhooks in your development environment, you'll need to configure a tunnel.".yellow
          puts "     See http://bullettrain.co/docs/tunneling for more information.".yellow
          puts ""
          puts "2. Once you have a tunnel running, you can configure the provider to deliver webhooks to:".yellow
          puts "     https://your-tunnel.ngrok.io/webhooks/incoming/#{provider_name.tableize.singularize}_webhooks".yellow
          puts ""

          transformer.restart_server
        end
      end
    end
  end
end
