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
    if uri.path == ""
      uri.path = "/"
    end

    http = Net::HTTP.new(hostname, uri.port)
    if uri.scheme == "https"
      http.use_ssl = true
      if BulletTrain::OutgoingWebhooks.http_verify_mode
        # Developers might need to set this to `OpenSSL::SSL::VERIFY_NONE` in some cases.
        http.verify_mode = BulletTrain::OutgoingWebhooks.http_verify_mode
      end
    end
    request = Net::HTTP::Post.new(uri.request_uri)
    request.add_field("Host", uri.host)
    request.add_field("Content-Type", "application/json")
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
