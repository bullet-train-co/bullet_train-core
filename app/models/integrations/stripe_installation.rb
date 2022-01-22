class Integrations::StripeInstallation < ApplicationRecord
  # 🚅 add concerns above.

  belongs_to :team
  belongs_to :oauth_stripe_account, class_name: "Oauth::StripeAccount"
  # 🚅 add belongs_to associations above.

  # 🚅 add has_many associations above.

  # 🚅 add has_one associations above.

  # 🚅 add scopes above.

  validates :name, presence: true
  # 🚅 add validations above.

  # 🚅 add callbacks above.

  # 🚅 add delegations above.

  def process_webhook(webhook)
    raise "You need to create a `app/models/integrations/stripe_installation.rb` file in your application that does a `Integrations::StripeInstallation.class_eval do ... end` and defines a `def process_webhook(webhook)` method."
  end

  # 🚅 add methods above.
end
