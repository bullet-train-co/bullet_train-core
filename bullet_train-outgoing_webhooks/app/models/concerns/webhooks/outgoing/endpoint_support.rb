module Webhooks::Outgoing::EndpointSupport
  extend ActiveSupport::Concern
  include Webhooks::Outgoing::UriFiltering

  included do
    belongs_to BulletTrain::OutgoingWebhooks.parent_association
    belongs_to :scaffolding_absolutely_abstract_creative_concept, optional: true, class_name: "Scaffolding::AbsolutelyAbstract::CreativeConcept"

    has_many :deliveries, class_name: "Webhooks::Outgoing::Delivery", dependent: :destroy, foreign_key: :endpoint_id
    has_many :events, -> { distinct }, through: :deliveries

    scope :listening_for_event_type_id, ->(event_type_id) { where("event_type_ids @> ? OR event_type_ids = '[]'::jsonb", "\"#{event_type_id}\"") }

    validates :name, presence: true

    before_validation { url&.strip! }

    validates :url, presence: true, allowed_uri: BulletTrain::OutgoingWebhooks.advanced_hostname_security

    after_initialize do
      self.event_type_ids ||= []
      self.api_version ||= I18n.t("webhooks/outgoing/endpoints.fields.api_version.options").keys.last
    end

    after_save :touch_parent
  end

  def valid_event_types
    Webhooks::Outgoing::EventType.all
  end

  def creative_concepts
    team.scaffolding_absolutely_abstract_creative_concepts
  end

  def event_types
    event_type_ids.map { |id| Webhooks::Outgoing::EventType.find(id) }
  end

  def touch_parent
    send(BulletTrain::OutgoingWebhooks.parent_association).touch
  end
end
