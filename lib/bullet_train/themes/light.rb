require "bullet_train/themes/light/version"
require "bullet_train/themes/light/engine"
require "bullet_train/themes/tailwind_css"

module BulletTrain
  module Themes
    module Light
      # TODO Not sure this is the right place for this in the long-term.
      mattr_accessor :color, default: :blue

      class Theme < BulletTrain::Themes::TailwindCss::Theme
        def directory_order
          ["light"] + super
        end
      end
    end
  end
end
