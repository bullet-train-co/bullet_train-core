5.times do |n|
  Team.create! name: "Generic name #{n}"
end

5.times do |n|
  Webhooks::Outgoing::Endpoint.find_or_create_by! team: Team.first, name: "Generic name #{n}", url: "http://example.com/webhook-#{n}"
end
