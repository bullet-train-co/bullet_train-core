require "bullet_train/themes/version"
require "bullet_train/themes/engine"

module BulletTrain
  module Themes
    mattr_accessor :themes, default: {}
  end
end
