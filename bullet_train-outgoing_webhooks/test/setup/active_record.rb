# Set so Active Record casts created_at/updated_at to ActiveSupport::TimeWithZone.
# (Matches Rails apps' default, but its assigned via Active Record's railtie.)
Time.zone = "UTC"
ActiveRecord::Base.time_zone_aware_attributes = true

# We declare a Team model here so that we can have it
# include Webhooks::Outgoing::TeamSupport
# which we don't ship enabled by default. Maybe we should?
#class Team < ApplicationRecord
  #include Teams::Base
  #include Webhooks::Outgoing::TeamSupport
#end
