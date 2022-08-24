require "bullet_train/themes/version"
require "bullet_train/themes/engine"
# require "bullet_train/themes/base/theme"

module BulletTrain
  module Themes
    mattr_accessor :themes, default: {}
    mattr_accessor :logo_height, default: 54

    mattr_reader :partial_paths, default: {}

    # TODO Do we want this to be configurable by downstream applications?
    INVOCATION_PATTERNS = [
      # ❌ This path is included for legacy purposes, but you shouldn't reference partials like this in new code.
      /^account\/shared\//,

      # ✅ This is the correct path to generically reference theme component partials with.
      /^shared\//,
    ]

    def self.theme_invocation_path_for(path)
      # Themes only support `<%= render 'shared/box' ... %>` style calls to `render`, so check `path` is a string first.
      if path.is_a?(String) && (pattern = INVOCATION_PATTERNS.find { _1.match? path })
        path.remove(pattern)
      end
    end

    module Base
      class Theme
        def directory_order
          ["base"]
        end

        def resolved_partial_path_for(lookup_context, path, locals)
          # TODO This caching should be disabled in development so new templates are taken into account without restarting the server.
          BulletTrain::Themes.partial_paths.fetch(path) do
            if (theme_path = BulletTrain::Themes.theme_invocation_path_for(path))
              # TODO directory_order should probably come from the `Current` model.
              if (partial = lookup_context.find_all(theme_path, directory_order.map { "themes/#{_1}" }, true, locals.keys).first)
                BulletTrain::Themes.partial_paths[path] = partial.virtual_path.gsub("/_", "/")
              end
            end
          end
        end
      end
    end
  end
end
