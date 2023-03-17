module BulletTrain
  module Themes
    module Light
      class Engine < ::Rails::Engine
        initializer "bullet_train.themes.light.register" do |app|
          BulletTrain::Themes.themes[:light] = BulletTrain::Themes::Light::Theme.new
        end
      end
    end
  end
end
