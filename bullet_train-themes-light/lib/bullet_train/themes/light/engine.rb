module BulletTrain
  module Themes
    module Light
      class Engine < ::Rails::Engine
        initializer "bullet_train.themes.light.register" do |app|
          BulletTrain::Themes.themes[:light] = BulletTrain::Themes::Light::Theme.new
          if BulletTrain.respond_to?(:linked_gems)
            BulletTrain.linked_gems << "bullet_train-themes-light"
          end
        end
      end
    end
  end
end
