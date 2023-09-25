module BulletTrain
  class Configuration
    include Singleton
    attr_accessor :strong_passwords, :enable_bulk_invitations, :incoming_webhooks_parent_class_name

    @@config = nil

    def initialize
      @@config = self

      # Default values
      @strong_passwords = true
      @enable_bulk_invitations = false
      @incoming_webhooks_parent_class_name = "ApplicationRecord"
    end

    class << self
      def strong_passwords
        @@config&.strong_passwords
      end

      def enable_bulk_invitations
        @@config&.enable_bulk_invitations
      end

      def incoming_webhooks_parent_class_name
        @@config&.incoming_webhooks_parent_class_name
      end
    end
  end
end
