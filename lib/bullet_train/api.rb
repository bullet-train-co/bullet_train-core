require "bullet_train/api/version"
require "bullet_train/api/engine"

module BulletTrain
  module Api
    mattr_accessor :endpoints, default: []
  end
end
