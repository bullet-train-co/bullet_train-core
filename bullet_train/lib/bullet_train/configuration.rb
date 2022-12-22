module BulletTrain
  class Configuration
    attr_accessor :strong_passwords

    @default = Configuration.new

    def initialize
      self.strong_passwords = true
    end

    class << self
      attr_reader :default
    end
  end
end
