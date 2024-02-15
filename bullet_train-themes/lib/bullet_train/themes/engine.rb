module BulletTrain
  unless respond_to?(:linked_gems)
    mattr_accessor :linked_gems, default: ["bullet_train-themes"]
  end

  module Themes
    class Engine < ::Rails::Engine
    end
  end
end
