require "bullet_train/version"
require "bullet_train/engine"
require "bullet_train/resolver"
require "bullet_train/configuration"

require "bullet_train/fields"
require "bullet_train/roles"
require "bullet_train/super_load_and_authorize_resource"
require "bullet_train/has_uuid"
require "bullet_train/scope_validator"

require "colorizer"
require "bullet_train/core_ext/string_emoji_helper"

require "devise"
require "xxhash"
# require "devise-two-factor"
# require "rqrcode"
require "cancancan"
require "possessive"
require "sidekiq"
require "fastimage"
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
require "pagy"
require "devise/pwned_password"

module BulletTrain
  mattr_accessor :routing_concerns, default: []
  mattr_accessor :linked_gems, default: ["bullet_train"]
  mattr_accessor :parent_class, default: "Team"
  mattr_accessor :base_class, default: "ApplicationRecord"

  def self.configure
    if block_given?
      yield(BulletTrain::Configuration.default)
    else
      BulletTrain::Configuration.default
    end
  end
end

def default_url_options_from_base_url
  unless ENV["BASE_URL"].present?
    if Rails.env.development?
      ENV["BASE_URL"] ||= "http://localhost:3000"
    else
      raise "you need to define the value of ENV['BASE_URL'] in your environment. if you're on heroku, you can do this with `heroku config:add BASE_URL=https://your-app-name.herokuapp.com` (or whatever your configured domain is)."
    end
  end

  parsed_base_url = URI.parse(ENV["BASE_URL"])
  default_url_options = [:user, :password, :host, :port].map { |key| [key, parsed_base_url.send(key)] }.to_h

  # the name of this property doesn't match up.
  default_url_options[:protocol] = parsed_base_url.scheme
  default_url_options.compact!

  if default_url_options.empty?
    raise "ENV['BASE_URL'] has not been configured correctly. Please check your environment variables and try one more time."
  end

  default_url_options
end

def inbound_email_enabled?
  ENV["INBOUND_EMAIL_DOMAIN"].present?
end

def billing_enabled?
  defined?(BulletTrain::Billing)
end

# TODO This should be in an initializer or something.
def billing_subscription_creation_disabled?
  false
end

def free_trial?
  ENV["STRIPE_FREE_TRIAL_LENGTH"].present?
end

def stripe_enabled?
  ENV["STRIPE_CLIENT_ID"].present?
end

# 🚅 super scaffolding will insert new oauth providers above this line.

def webhooks_enabled?
  true
end

def scaffolding_things_disabled?
  ENV["HIDE_THINGS"].present? || ENV["HIDE_EXAMPLES"].present?
end

def sample_role_disabled?
  ENV["HIDE_EXAMPLES"].present?
end

def demo?
  ENV["DEMO"].present?
end

def cloudinary_enabled?
  ENV["CLOUDINARY_URL"].present?
end

def two_factor_authentication_enabled?
  Rails.application.credentials.active_record_encryption&.primary_key.present?
end

# Don't redefine this if an application redefines it locally.
unless defined?(any_oauth_enabled?)
  def any_oauth_enabled?
    [
      stripe_enabled?,
      # 🚅 super scaffolding will insert new oauth provider checks above this line.
    ].select(&:present?).any?
  end
end

def invitation_only?
  ENV["INVITATION_KEYS"].present?
end

def invitation_keys
  ENV["INVITATION_KEYS"].split(",").map(&:strip)
end

def font_awesome?
  ENV["FONTAWESOME_NPM_AUTH_TOKEN"].present?
end

def multiple_locales?
  @multiple_locales ||= I18n.available_locales.many?
end

def silence_logs?
  ENV["SILENCE_LOGS"].present?
end
