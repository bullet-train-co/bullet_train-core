module BulletTrain
  class Configuration
    include Singleton
    attr_accessor :strong_passwords

    def initialize
      @@config = self

      # Default values
      @strong_passwords = true
    end

    class << self
      def strong_passwords
        @@config.strong_passwords
      end
    end
  end
end
