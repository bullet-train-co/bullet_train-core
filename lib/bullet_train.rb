require "bullet_train/version"
require "bullet_train/engine"

module BulletTrain
  mattr_accessor :routing_concerns, default: []
end
