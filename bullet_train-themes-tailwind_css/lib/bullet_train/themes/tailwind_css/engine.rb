module BulletTrain
  module Themes
    module TailwindCss
      class Engine < ::Rails::Engine
        initializer "bullet_train.themes.tailwind_css.register" do |app|
          if BulletTrain.respond_to?(:linked_gems)
            BulletTrain.linked_gems << "bullet_train-themes-tailwind_css"
          end
        end
      end
    end
  end
end
