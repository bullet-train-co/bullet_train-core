require "bullet_train/version"
require "bullet_train/engine"

require "bullet_train/fields"
require "bullet_train/roles"
require "bullet_train/super_load_and_authorize_resource"
require "bullet_train/has_uuid"
require "bullet_train/scope_validator"

module BulletTrain
  mattr_accessor :routing_concerns, default: []
  mattr_accessor :linked_gems, default: ["bullet_train"]
end
