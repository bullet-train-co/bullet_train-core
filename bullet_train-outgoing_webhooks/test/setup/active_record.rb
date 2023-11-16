# Set so Active Record casts created_at/updated_at to ActiveSupport::TimeWithZone.
# (Matches Rails apps' default, but its assigned via Active Record's railtie.)
Time.zone = "UTC"
ActiveRecord::Base.time_zone_aware_attributes = true

class Webhooks::Outgoing::Delivery; end

class Team < ApplicationRecord
  include Teams::Base
  include Webhooks::Outgoing::TeamSupport
end
