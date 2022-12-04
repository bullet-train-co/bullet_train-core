require "bullet_train/integrations/stripe/version"
require "bullet_train/integrations/stripe/engine"

require "stripe"
require "omniauth"
require "omniauth-stripe-connect"

# TODO Remove when we're able to properly upgrade Omniauth.
# https://github.com/omniauth/omniauth/wiki/Resolving-CVE-2015-9284
require "omniauth/rails_csrf_protection"

module BulletTrain
  module Integrations
    module Stripe
      # Your code goes here...
    end
  end
end
