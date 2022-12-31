module Webhooks::Outgoing::TeamSupport
  extend ActiveSupport::Concern

  included do
    has_many :webhooks_outgoing_endpoints, class_name: "Webhooks::Outgoing::Endpoint", dependent: :destroy
    has_many :webhooks_outgoing_events, class_name: "Webhooks::Outgoing::Event", dependent: :destroy

    before_destroy :mark_for_destruction, prepend: true
  end

  def should_cache_endpoints_listening_for_event_type?
    true
  end

  def endpoint_api_versions_for_event_type(event_type)
    webhooks_outgoing_endpoints.listening_for_event_type_id(event_type.id).pluck(:api_version).uniq
  end

  def endpoint_api_versions_listening_for_event_type(event_type)
    if should_cache_endpoints_listening_for_event_type?
      key = "#{cache_key_with_version}/endpoints_for_event_type/#{event_type.cache_key}/api_version"

      Rails.cache.fetch(key, expires_in: 24.hours, race_condition_ttl: 5.seconds) do
        endpoint_api_versions_for_event_type(event_type)
      end
    else
      endpoint_api_versions_for_event_type(event_type)
    end
  end

  def mark_for_destruction
    # This allows downstream logic to check whether a team is being destroyed in order to bypass webhook issuance.
    update_column(:being_destroyed, true)
  end
end
