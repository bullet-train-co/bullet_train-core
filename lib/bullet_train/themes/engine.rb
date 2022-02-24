module BulletTrain
  module Themes
    class Engine < ::Rails::Engine
      initializer "bullet_train.themes.register" do |app|
        BulletTrain.linked_gems << "bullet_train-themes"
      end
    end
  end
end
