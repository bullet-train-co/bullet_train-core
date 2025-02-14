module BulletTrain
  module Api
    class Configuration
      attr_accessor :nonce_generator

      def initialize
        # Default to BulletTrain::Api.configuration.nonce_generator.call
        @nonce_generator = -> { BulletTrain::Api.configuration.nonce_generator.call }
      end
    end

    def self.configuration
      @configuration ||= Configuration.new
    end

    def self.configure
      yield(configuration)
    end
  end
end
