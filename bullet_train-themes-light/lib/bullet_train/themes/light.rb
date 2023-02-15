require "bullet_train/themes/light/version"
require "bullet_train/themes/light/engine"
require "bullet_train/themes/tailwind_css"
require "bullet_train/themes/light/file_replacer"
require "bullet_train/themes/light/custom_theme_file_replacer"

module BulletTrain
  module Themes
    module Light
      # TODO Not sure this is the right place for this in the long-term.
      mattr_accessor :color, default: :blue
      mattr_accessor :secondary_color, default: nil
      mattr_accessor :background, default: nil
      mattr_accessor :logo_color_shift, default: false
      mattr_accessor :show_logo_in_account, default: false
      mattr_accessor :navigation, default: :top
      mattr_accessor :original_devise_path # TODO: Obsolete: remove after shipping a new BulletTrain version with usage removed.

      class Theme < BulletTrain::Themes::TailwindCss::Theme
        def directory_order
          ["light"] + super
        end
      end
    end
  end
end
