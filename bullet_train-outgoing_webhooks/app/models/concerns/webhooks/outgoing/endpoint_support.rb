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
    Webhooks::Outgoing::EventType.where(id: event_type_ids)
  end

  def touch_parent
    send(BulletTrain::OutgoingWebhooks.parent_association).touch
  end

  def active?
    deactivated_at.nil?
  end

  def deactivated?
    deactivated_at.present?
  end

  def marked_for_deactivation?
    deactivation_limit_reached_at.present? && deactivated_at.nil?
  end

  def clear_deactivation_limit_reached_at!
    update(deactivation_limit_reached_at: nil)
  end

  def deactivate!
    return if deactivated?

    update(deactivated_at: Time.current)
  end

  def mark_for_deactivation!
    return if marked_for_deactivation?
    return if deactivated?

    update(deactivation_limit_reached_at: Time.current)
  end

  def deactivation_processing
    return unless BulletTrain::OutgoingWebhooks::Engine.config.outgoing_webhooks[:automatic_endpoint_deactivation_enabled]
    return if deactivated?

    # If the endpoint is marked for deactivation, we check if the cooling-off period (deactivation_in setting) has passed. If so, we mark it as deactivated.
    if should_be_deactivated?
      deactivate!
    elsif should_be_marked_for_deactivation?
      mark_for_deactivation!
    end
  end

  def should_be_deactivated?
    return false unless deactivation_limit_reached_at
    return false if deactivated_at

    deactivation_limit_reached_at <= BulletTrain::OutgoingWebhooks::Engine.config.outgoing_webhooks.dig(:automatic_endpoint_deactivation_settings, :deactivation_in).ago
  end

  def should_be_marked_for_deactivation?
    return false if deactivated?
    return false if deactivation_limit_reached_at

    max_attempts_period = Webhooks::Outgoing::Delivery.max_attempts_period + 1.hour # Adding 1 hour to ensure it covers all delays
    max_limit = BulletTrain::OutgoingWebhooks::Engine.config.outgoing_webhooks.dig(:automatic_endpoint_deactivation_settings, :max_limit)
    last_successful_delivery = deliveries.where.not(delivered_at: nil).maximum(:delivered_at)
    return false if last_successful_delivery && last_successful_delivery < (Webhooks::Outgoing::Delivery.max_attempts_period + 1.hour).ago

    deliveries.where(delivered_at: nil).where("created_at < ?", max_attempts_period.ago).last(max_limit).pluck(:delivered_at).all?(&:nil?)
  end
end
