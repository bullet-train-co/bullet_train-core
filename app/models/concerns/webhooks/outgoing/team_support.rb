module Webhooks::Outgoing::TeamSupport
  extend ActiveSupport::Concern

  included do
    has_many :webhooks_outgoing_endpoints, class_name: "Webhooks::Outgoing::Endpoint", dependent: :destroy
    has_many :webhooks_outgoing_events, class_name: "Webhooks::Outgoing::Event", dependent: :destroy

    before_destroy :mark_for_destruction, prepend: true
  end

  def mark_for_destruction
    # This allows downstream logic to check whether a team is being destroyed in order to bypass webhook issuance.
    update_column(:being_destroyed, true)
  end
end
