require "bullet_train/version"
require "bullet_train/engine"
require "bullet_train/resolver"
require "bullet_train/configuration"

require "bullet_train/fields"
require "bullet_train/roles"
require "bullet_train/super_load_and_authorize_resource"
require "bullet_train/has_uuid"
require "bullet_train/scope_validator"

require "exceptions"

# NOTE: This is requiring the `colorizer.rb` file that lives in the same directory as this file. It looks like it's requiring a gem, but it's not.
require "colorizer"
require "bullet_train/core_ext/string_emoji_helper"

require "devise"
# require "devise-two-factor"
# require "rqrcode"
require "cancancan"
require "possessive"
require "fastimage"
require "http_accept_language"
require "cable_ready"
require "nice_partials"
require "figaro"
require "commonmarker"
require "pagy"
require "devise/pwned_password"

module BulletTrain
  mattr_accessor :routing_concerns, default: []
  mattr_accessor :linked_gems, default: ["bullet_train"]
  mattr_accessor :parent_class, default: "Team"
  mattr_accessor :base_class, default: "ApplicationRecord"

  def self.configure
    config = BulletTrain::Configuration.instance
    yield(config) if block_given?
  end
end

def default_url_options_from_base_url
  unless ENV["BASE_URL"].present?
    if Rails.env.development?
      ENV["BASE_URL"] = "http://localhost:3000"
    else
      return {}
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

def heroku?
  # This is a value we set in `app.json` so anyone using the "Deploy to Heroku" button
  # should have it. This is kind of a brute force method that should be future-proofed
  # against changes that Heroku might make to their runtime environment. We'll fallback
  # to some additional checks if this isn't here, to maintain backwards compatibility
  # for existing apps.
  if ENV["BT_IS_IN_HEROKU"].present?
    ENV["BT_IS_IN_HEROKU"] == "true"
  else
    # This requires the app to run `heroku labs:enable runtime-dyno-metadata` and then
    # deploy at least once before the ENV var is set. Many existing BT apps have enabled
    # this feature, and this used to be the only detection method that we had. We're
    # keeping it for backwards compability reasons because it's probably more stable
    # than the following fallbacks.
    ENV["HEROKU_APP_NAME"].present? ||
      # And finally we fallback to checking for some artifacts that Heroku happens to leave
      # lying around. These may change in the future, so who knows how long they'll be good.
      #
      # If there's a `DYNO` ENV var, then we're probably on Heroku. Will they _always_ set
      # this variable?
      ENV["DYNO"].present? ||
      # Finally we look for the the existence of the `/app/.heroku` directory.
      # This should make detection work for apps that don't have any of the above ENV vars, for
      # whatever reasons. But, in the future Heroku could decide to remove `/app/.heroku`
      # which will break this fallback method and then we'll have to come up with something else.
      # This is currently our last line of defense.
      File.directory?("/app/.heroku")
  end
end

def inbound_email_enabled?
  ENV["INBOUND_EMAIL_DOMAIN"].present?
end

def billing_enabled?
  (ENV["STRIPE_SECRET_KEY"].present? || ENV["PADDLE_SECRET_KEY"].present?) && defined?(BulletTrain::Billing)
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

def hide_things?
  ActiveModel::Type::Boolean.new.cast(ENV["HIDE_THINGS"])
end

def hide_examples?
  ActiveModel::Type::Boolean.new.cast(ENV["HIDE_EXAMPLES"])
end

def scaffolding_things_disabled?
  hide_things? || hide_examples?
end

def sample_role_disabled?
  hide_examples?
end

def demo?
  ENV["DEMO"].present?
end

def cloudinary_enabled?
  ENV["CLOUDINARY_URL"].present?
end

def two_factor_authentication_enabled?
  Rails.application.credentials.active_record_encryption&.primary_key.present? || Rails.configuration&.active_record&.encryption&.primary_key.present?
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

def openai_enabled?
  if ENV["OPENAI_ACCESS_TOKEN"].present? && !defined?(OpenAI)
    Rails.logger.warn "OpenAI access token is set, but the OpenAI gem is not loaded. Please add the 'ruby-openai' gem to your Gemfile to enable OpenAI features."
  end

  if !ENV["OPENAI_ACCESS_TOKEN"].present? && defined?(OpenAI)
    Rails.logger.warn "OpenAI access token is not set, but the OpenAI gem is loaded. Please set the OPENAI_ACCESS_TOKEN environment variable to enable OpenAI features."
  end

  ENV["OPENAI_ACCESS_TOKEN"].present? && defined?(OpenAI)
end

def openai_organization_exists?
  ENV["OPENAI_ORGANIZATION_ID"]
end

def bulk_invitations_enabled?
  BulletTrain::Configuration.enable_bulk_invitations
end

def disable_developer_menu?
  ENV["DISABLE_DEVELOPER_MENU"].present?
end
