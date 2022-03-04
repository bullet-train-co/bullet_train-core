require "bullet_train/version"
require "bullet_train/engine"

require "bullet_train/fields"
require "bullet_train/roles"
require "bullet_train/super_load_and_authorize_resource"
require "bullet_train/has_uuid"
require "bullet_train/scope_validator"

require "devise"
# require "devise-two-factor"
# require "rqrcode"
require "cancancan"
require "possessive"
require "sidekiq"
require "fastimage"
require "pry"
require "pry-stack_explorer"
require "awesome_print"
require "microscope"
require "http_accept_language"
require "cable_ready"
require "hiredis"
require "nice_partials"
require "premailer/rails"
require "figaro"
require "valid_email"
require "commonmarker"
require "extended_email_reply_parser"

module BulletTrain
  mattr_accessor :routing_concerns, default: []
  mattr_accessor :linked_gems, default: ["bullet_train"]
end
