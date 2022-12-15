require "active_record"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

# Set so Active Record casts created_at/updated_at to ActiveSupport::TimeWithZone.
# (Mathces Rails apps' default, but its assigned via Active Record's railtie.)
Time.zone = "UTC"
ActiveRecord::Base.time_zone_aware_attributes = true

ActiveRecord::Schema.define do
  create_table :teams, force: true do |t|
    t.string :name, null: false
    t.timestamps null: false
  end

  create_table :webhooks_outgoing_endpoints, force: true do |t|
    t.references :team
    t.string :url, null: false
    t.string :name, null: false
    t.integer :event_type_ids, array: true, default: []
    t.timestamps null: false
  end

  create_table :webhooks_outgoing_deliveries, force: true do |t|
    t.references :team
    t.references :endpoint
  end
end

class Team < ActiveRecord::Base
  has_many :webhooks_outgoing_endpoints, class_name: "Webhooks::Outgoing::Endpoint"
end

class Webhooks::Outgoing::Delivery; end

5.times do |n|
  Team.create! name: "Generic name #{n}"
end

5.times do |n|
  Webhooks::Outgoing::Endpoint.create! team_id: Team.first.id, name: "Generic name #{n}", url: "http://example.com/webhook-#{n}"
end
