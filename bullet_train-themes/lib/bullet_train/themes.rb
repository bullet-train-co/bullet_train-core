# frozen_string_literal: true

require "bullet_train/themes/version"
require "bullet_train/themes/engine"
# require "bullet_train/themes/base/theme"

module BulletTrain
  module Themes
    mattr_accessor :themes, default: {}
    mattr_accessor :logo_height, default: 54

    # TODO Do we want this to be configurable by downstream applications?
    INVOCATION_PATTERNS = Regexp.union(
      /^account\/shared\//, # ❌ This path is included for legacy purposes, but you shouldn't reference partials like this in new code.
      /^shared\//, # ✅ This is the correct path to generically reference theme component partials with.
    )

    def self.theme_invocation_path_for(path)
      # Themes only support `<%= render 'shared/box' ... %>` style calls to `render`, so check `path` is a string first.
      path.dup.gsub!(INVOCATION_PATTERNS, "") if path.is_a?(String)
    end

    module Base
      class Theme
        def directory_order
          ["base"]
        end

        def prefixes
          @prefixes ||= directory_order.map { "themes/#{_1}" }
        end
      end
    end
  end
end
