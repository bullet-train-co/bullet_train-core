require "bullet_train/themes/version"
require "bullet_train/themes/engine"
# require "bullet_train/themes/base/theme"

module BulletTrain
  module Themes
    mattr_accessor :themes, default: {}
    mattr_accessor :logo_asset_path, default: "logo/logo.png"
    mattr_accessor :logo_height, default: 54

    module Base
      class Theme
        def directory_order
          ['base']
        end
      end
    end
  end
end
