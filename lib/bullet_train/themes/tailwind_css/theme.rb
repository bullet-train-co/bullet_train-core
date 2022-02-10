require "bullet_train/themes/base"

module BulletTrain
  module Themes
    module TailwindCss
      class Theme < Base::Theme
        def directory_order
          ['tailwind'] + super
        end
      end
    end
  end
end
