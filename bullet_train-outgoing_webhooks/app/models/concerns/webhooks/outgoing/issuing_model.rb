module Webhooks::Outgoing::IssuingModel
  extend ActiveSupport::Concern

  # define relationships.
  included do
    after_commit :generate_created_webhook, on: [:create]
    after_commit :generate_updated_webhook, on: [:update]
    after_commit :generate_deleted_webhook, on: [:destroy]
    has_many :webhooks_outgoing_events, as: :subject, class_name: "Webhooks::Outgoing::Event", dependent: :nullify
  end

  def skip_generate_webhook?(action)
    false
  end

  # TODO This should probably be called `outgoing_webhooks_parent` to avoid colliding with downstream `parent` methods.
  def parent
    return unless respond_to? BulletTrain::OutgoingWebhooks.parent_association
    send(BulletTrain::OutgoingWebhooks.parent_association)
  end

  def generate_webhook(action, async: true)
    # allow individual models to opt out of generating webhooks
    return if skip_generate_webhook?(action)

    # we can only generate webhooks for objects that return their their team / parent.
    return unless parent.present?

    # Try to find an event type definition for this action.
    event_type = Webhooks::Outgoing::EventType.find_by(id: "#{self.class.name.underscore}.#{action}")

    # If the event type is defined as one that people can be subscribed to,
    # and this object has a parent where an associated outgoing webhooks endpoint could be registered.
    if event_type
      # Only generate an event record if an endpoint is actually listening for this event type.
      # If there are endpoints listening, make sure we know which API versions they're looking for.
      if (api_versions = parent.endpoint_api_versions_listening_for_event_type(event_type)).any?
        if async
          # serialization can be heavy so run it as a job
          Webhooks::Outgoing::GenerateJob.perform_later(self, action, api_versions)
        else
          generate_webhook_perform(action, api_versions)
        end
      end
    end
  end

  def generate_webhook_perform(action, api_versions)
    event_type = Webhooks::Outgoing::EventType.find_by(id: "#{self.class.name.underscore}.#{action}")

    api_versions.each do |api_version|
      webhook = send(BulletTrain::OutgoingWebhooks.parent_association).webhooks_outgoing_events.create(
        event_type_id: event_type.id,
        subject: self,
        data: api_attributes(api_version),
        api_version: api_version
      )

      webhook.deliver
    end
  end

  def generate_created_webhook
    generate_webhook(:created)
  end

  def generate_updated_webhook
    generate_webhook(:updated)
  end

  def generate_deleted_webhook
    return false unless parent.present?
    return false if parent.being_destroyed?

    generate_webhook(:deleted, async: false)
  end
end
