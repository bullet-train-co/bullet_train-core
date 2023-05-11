module Webhooks::Outgoing::DeliveryAttemptSupport
  extend ActiveSupport::Concern
  include Webhooks::Outgoing::UriFiltering

  SUCCESS_RESPONSE_CODES = [200, 201, 202, 203, 204, 205, 206, 207, 226].freeze

  included do
    belongs_to :delivery
    has_one :team, through: :delivery unless BulletTrain::OutgoingWebhooks.parent_class_specified?
    scope :successful, -> { where(response_code: SUCCESS_RESPONSE_CODES) }

    before_create do
      self.attempt_number = delivery.attempt_count + 1
    end

    validates :response_code, presence: true
  end

  def still_attempting?
    error_message.nil? && response_code.nil?
  end

  def successful?
    SUCCESS_RESPONSE_CODES.include?(response_code)
  end

  def failed?
    !(successful? || still_attempting?)
  end

  def compute_signature(payload)
    raise ArgumentError, "payload should be a string" unless payload.is_a?(String)

    unless delivery.team.webhooks_signing_secret.present?
      delivery.team.update(webhooks_signing_secret: SecureRandom.hex(32))
    end
    secret = delivery.team.webhooks_signing_secret
    timestamp = Time.now

    timestamped_payload = "#{timestamp.to_i}.#{payload}"
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), secret,
                            timestamped_payload)
  end

  def attempt
    uri = URI.parse(delivery.endpoint_url)

    if BulletTrain::OutgoingWebhooks.advanced_hostname_security
      unless allowed_uri?(uri)
        self.response_code = 0
        self.error_message = "URI is not allowed: " + uri
        return false
      end
    end

    hostname = if BulletTrain::OutgoingWebhooks.advanced_hostname_security
      resolve_ip_from_authoritative(uri.hostname.downcase)
    else
      uri.hostname.downcase
    end

    # Net::HTTP will consider the url invalid (and not deliver the webhook) unless it ends with a '/'
    unless uri.path.end_with?("/")
      uri.path = uri.path + "/"
    end

    signature = compute_signature(delivery.event.payload.to_s)

    http = Net::HTTP.new(hostname, uri.port)
    http.use_ssl = true if uri.scheme == "https"
    request = Net::HTTP::Post.new(uri.path)
    request.add_field("Host", uri.host)
    request.add_field("Content-Type", "application/json")
    request.add_field("Bullet-Train-Signature", signature)
    request.body = delivery.event.payload.to_json

    begin
      response = http.request(request)
      self.response_message = response.message
      self.response_code = response.code
      self.response_body = response.body
    rescue => exception
      self.response_code = 0
      self.error_message = exception.message
    end

    save
    successful?
  end

  def label_string
    "#{attempt_number.ordinalize} Attempt"
  end
end
