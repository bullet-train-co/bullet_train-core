module Webhooks::Outgoing::EventSupport
  extend ActiveSupport::Concern
  include HasUuid

  included do
    belongs_to BulletTrain::OutgoingWebhooks.parent_association
    belongs_to :event_type, class_name: "Webhooks::Outgoing::EventType"
    belongs_to :subject, polymorphic: true
    has_many :deliveries, dependent: :destroy

    before_create do
      self.payload = generate_payload
    end
  end

  def generate_payload
    {
      event_id: uuid,
      event_type: event_type_id,
      subject_id: subject_id,
      subject_type: subject_type,
      data: data
    }
  end

  def event_type_name
    payload.dig("event_type")
  end

  def endpoints
    endpoints = send(BulletTrain::OutgoingWebhooks.parent_association).webhooks_outgoing_endpoints.where(api_version: api_version).listening_for_event_type_id(event_type_id)

    case subject_type
    when "Scaffolding::AbsolutelyAbstract::CreativeConcept"
      endpoints.where(scaffolding_absolutely_abstract_creative_concept_id: [subject.id, nil])
    when "Scaffolding::CompletelyConcrete::TangibleThing"
      endpoints.where(scaffolding_absolutely_abstract_creative_concept_id: [subject.absolutely_abstract_creative_concept_id, nil])
    else
      endpoints
    end
  end

  def deliver
    endpoints.each do |endpoint|
      unless endpoint.deliveries.where(event: self).any?
        endpoint.deliveries.create(event: self, endpoint_url: endpoint.url).deliver_async
      end
    end
  end

  def label_string
    short_uuid
  end
end
