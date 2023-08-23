module BulletTrain
  class Configuration
    include Singleton
    attr_accessor :strong_passwords, :incoming_webhooks_parent_class_name

    @@config = nil

    def initialize
      @@config = self

      # Default values
      @strong_passwords = true
    end

    class << self
      def strong_passwords
        @@config&.strong_passwords
      end

      def incoming_webhooks_parent_class_name
        @@config&.incoming_webhooks_parent_class_name
      end
    end
  end
end
