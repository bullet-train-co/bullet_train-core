require "scaffolding/incoming_webhooks_transformer"
require "pry"

module BulletTrain
  module IncomingWebhooks
    module Scaffolders
      class IncomingWebhooksScaffolder < SuperScaffolding::Scaffolder
        def run
          unless argv.count >= 1
            puts ""
            puts "🚅 usage: bin/super-scaffold incoming-webhooks SomeProvider"
            puts ""
            puts "E.g." # TODO: Provide a solid example.
          end

          provider_name = argv.shift
          transformer = Scaffolding::IncomingWebhooksTransformer.new(provider_name)

          `yes n | bin/rails g model webhooks_incoming_#{provider_name.tableize.singularize}_webhook data:jsonb processed_at:datetime verified_at:datetime`

          transformer.scaffold_incoming_webhook
          transformer.restart_server
        end
      end
    end
  end
end
