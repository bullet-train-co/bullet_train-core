require "bullet_train/themes/tailwind_css"

module BulletTrain
  module Themes
    module Light
      class Theme < TailwindCss::Theme
        def directory_order
          ['light'] + super
        end
      end
    end
  end
end
