require "bullet_train/themes/tailwind_css/version"
require "bullet_train/themes/tailwind_css/engine"
require "bullet_train/themes"
require "bullet_train"

module BulletTrain
  module Themes
    module TailwindCss
      class Theme < BulletTrain::Themes::Base::Theme
        def directory_order
          ["tailwind_css"] + super
        end
      end
    end
  end
end
