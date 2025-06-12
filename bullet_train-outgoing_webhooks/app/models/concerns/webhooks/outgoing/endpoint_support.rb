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
    before_validation :generate_webhook_secret, on: :create

    validates :url, presence: true, allowed_uri: BulletTrain::OutgoingWebhooks.advanced_hostname_security
    validates :webhook_secret, presence: true

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
    Webhooks::Outgoing::EventType.where(id: event_type_ids)
  end

  def touch_parent
    send(BulletTrain::OutgoingWebhooks.parent_association).touch
  end

  def generate_webhook_secret
    self.webhook_secret ||= SecureRandom.hex(32)
  end

  def rotate_webhook_secret!
    update!(webhook_secret: SecureRandom.hex(32))
  end
end
