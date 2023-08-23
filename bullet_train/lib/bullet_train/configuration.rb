module BulletTrain
  class Configuration
    include Singleton
    attr_accessor :strong_passwords, :enable_bulk_invitations

    @@config = nil

    def initialize
      @@config = self

      # Default values
      @strong_passwords = true
      @enable_bulk_invitations = false
    end

    class << self
      def strong_passwords
        @@config&.strong_passwords
      end

      def enable_bulk_invitations
        @@config&.enable_bulk_invitations
      end
    end
  end
end
