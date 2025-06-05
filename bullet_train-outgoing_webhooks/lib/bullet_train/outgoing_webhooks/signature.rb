module BulletTrain
  module OutgoingWebhooks
    # Provides methods for webhook signatures. This module also serves as an
    # example that can be used by receiving applications to verify webhook
    # authenticity.
    module Signature
      # Verifies the authenticity of a webhook request.
      #
      # @param payload [String] The raw request body as a string.
      # @param timestamp [String] The timestamp from the Timestamp request header.
      # @param signature [String] The signature from the Signature request header.
      # @param secret [String] The webhook secret attached to the endpoint the event comes from.
      # @return [Boolean] True if the signature is valid, false otherwise.
      def self.verify(payload, signature, timestamp, secret)
        return false if payload.blank? || signature.blank? || timestamp.blank? || secret.blank?

        tolerance = Rails.configuration.outgoing_webhooks[:event_verification_tolerance_seconds]
        # Check if the timestamp is too old
        timestamp_int = timestamp.to_i
        now = Time.now.to_i

        if (now - timestamp_int).abs > tolerance
          return false # Webhook is too old or timestamp is from the future
        end

        # Compute the expected signature
        signature_payload = "#{timestamp}.#{payload}"
        expected_signature = OpenSSL::HMAC.hexdigest("SHA256", secret, signature_payload)

        # Compare signatures using constant-time comparison to prevent timing attacks
        ActiveSupport::SecurityUtils.secure_compare(expected_signature, signature)
      end

      # A Rails controller helper example to verify webhook requests.
      #
      # @param request [ActionDispatch::Request] The Rails request object.
      # @param secret [String] The webhook secret shared with the sender.
      # @return [Boolean] True if the signature is valid, false otherwise.
      def self.verify_request(request, secret)
        return false if request.blank? || secret.blank?

        webhook_headers_namespace = Rails.configuration.outgoing_webhooks[:webhook_headers_namespace]
        signature = request.headers["#{webhook_headers_namespace}-Signature"]
        timestamp = request.headers["#{webhook_headers_namespace}-Timestamp"]
        payload = request.raw_post

        return false if signature.blank? || timestamp.blank?

        verify(payload, signature, timestamp, secret)
      end

      # Algorithm to generate the signature.
      #
      # @payload [Hash] The payload to be encoded into a signature.
      # @secret [String] The secret stored on each webhook endpoint.
      def self.generate(payload, secret)
        timestamp = Time.now.to_i.to_s
        signature_payload = "#{timestamp}.#{payload.to_json}"
        signature = OpenSSL::HMAC.hexdigest("SHA256", secret, signature_payload)

        {
          signature: signature,
          timestamp: timestamp
        }
      end
    end
  end
end
