module BulletTrain
  module OutgoingWebhooks
    class Engine < ::Rails::Engine
      config.before_configuration do
        default_blocked_cidrs = %w[
          10.0.0.0/8
          172.16.0.0/12
          192.168.0.0/16
          100.64.0.0/10
          127.0.0.0/8
          169.254.169.254/32
          fc00::/7
          ::1
        ]

        config.outgoing_webhooks = {
          blocked_cidrs: default_blocked_cidrs,
          allowed_cidrs: [],
          blocked_hostnames: %w[localhost],
          allowed_hostnames: [],
          public_resolvers: %w[8.8.8.8 1.1.1.1],
          allowed_schemes: %w[http https],
          custom_block_callback: nil,
          custom_allow_callback: nil,
          audit_callback: ->(obj, uri) { Rails.logger.error("BlockedURI obj=#{obj.persisted? ? obj.to_global_id : "New #{obj.class}"} uri=#{uri}") }
        }
      end
    end
  end
end
