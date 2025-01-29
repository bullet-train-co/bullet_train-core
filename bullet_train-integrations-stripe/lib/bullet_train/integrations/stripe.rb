require "bullet_train/integrations/stripe/version"
require "bullet_train/integrations/stripe/engine"

require "stripe"
require "omniauth"
require "omniauth-stripe-connect-v2"

# This helps to resolve this CVE:
# https://github.com/omniauth/omniauth/wiki/Resolving-CVE-2015-9284
# It also just allows things to work as expected.
# Initially it seemed like we could remove this gem after updating omniauth
# to version > 2. But If we remove it the built-in TokenValidator from omniauth
# throws an error when we try to connect.
require "omniauth/rails_csrf_protection"

module BulletTrain
  module Integrations
    module Stripe
      # Your code goes here...
    end
  end
end
