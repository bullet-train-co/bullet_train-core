# frozen_string_literal: true

require_relative "internationalization/version"

module BulletTrain
  module Internationalization
    class << self
      def locales
        root = (File.dirname __dir__).gsub("/lib", "")
        Dir.glob("#{root}/config/locales/**/*.yml")
      end
    end

    class Error < StandardError; end
  end
end
