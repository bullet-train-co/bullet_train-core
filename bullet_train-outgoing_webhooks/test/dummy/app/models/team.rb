class Team < ApplicationRecord
  has_many :webhooks_outgoing_endpoints, class_name: "Webhooks::Outgoing::Endpoint"
end
