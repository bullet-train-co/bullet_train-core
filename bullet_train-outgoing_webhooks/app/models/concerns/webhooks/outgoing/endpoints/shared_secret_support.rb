module Webhooks::Outgoing::Endpoints::SharedSecretSupport
  extend ActiveSupport::Concern

  CURRENT_VERSION = "v1"

  included do
    belongs_to :endpoint, class_name: "Webhooks::Outgoing::Endpoint"

    has_many :delivery_attempts, class_name: "Webhooks::Outgoing::DeliveryAttempt", foreign_key: :shared_secret_id

    scope :active_for_timestamp, ->(timestamp) { where("expires_at is null or expires_at < ?", timestamp) }
    scope :active, -> { active_for_timestamp(Time.now) }
  end

  def generate_signature(timestamp, payload_string)
    CURRENT_VERSION + "=" + OpenSSL::HMAC.hexdigest("SHA256", secret, [timestamp.to_s, payload_string].join("."))
  end

  def signature_valid?(timestamp, payload_string, signature)
    test_sig = generate_signature(timestamp, payload_string)
    ActiveSupport::SecurityUtils.secure_compare(test_sig, signature)
  end
end
