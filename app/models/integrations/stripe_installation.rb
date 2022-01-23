class Integrations::StripeInstallation < ApplicationRecord
  include Integrations::StripeInstallations::Base

  def process_webhook(webhook)
    raise "You should implement a `Integrations::StripeInstallation` model in your application that has `include Integrations::StripeInstallations::Base` and implements a `def process_webhook(webhook)` method."
  end
end
