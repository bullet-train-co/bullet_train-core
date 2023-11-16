# Set so Active Record casts created_at/updated_at to ActiveSupport::TimeWithZone.
# (Matches Rails apps' default, but its assigned via Active Record's railtie.)
Time.zone = "UTC"
ActiveRecord::Base.time_zone_aware_attributes = true

class Webhooks::Outgoing::Delivery; end

5.times do |n|
  Team.create! name: "Generic name #{n}"
end

5.times do |n|
  Webhooks::Outgoing::Endpoint.create! team_id: Team.first.id, name: "Generic name #{n}", url: "http://example.com/webhook-#{n}"
end
