require "test_helper"

class BulletTrain::OutgoingWebhooks::SignatureVerificationTest < ActiveSupport::TestCase
  setup do
    @secret = "test-webhook-secret"
    payload_hash = {"test" => "data"}
    @payload = payload_hash.to_json

    signature_data = BulletTrain::OutgoingWebhooks::SignatureVerification.generate_signature(
      payload_hash,
      @secret
    )
    @valid_signature = signature_data[:signature]
    @timestamp = signature_data[:timestamp]
  end

  test "#verify_signature returns true for valid signatures" do
    result = BulletTrain::OutgoingWebhooks::SignatureVerification.verify_signature(
      @payload,
      @valid_signature,
      @timestamp,
      @secret
    )

    assert result, "Should return true for valid signature"
  end

  test "#verify_signature returns false for wrong webhook secret" do
    result = BulletTrain::OutgoingWebhooks::SignatureVerification.verify_signature(
      @payload,
      @valid_signature,
      @timestamp,
      "making-this-up"
    )

    assert_not result, "Should return false for wrong webhook secret"
  end

  test "#verify_signature returns false for invalid signatures" do
    invalid_signature = "invalid" + @valid_signature[7..]

    result = BulletTrain::OutgoingWebhooks::SignatureVerification.verify_signature(
      @payload,
      invalid_signature,
      @timestamp,
      @secret
    )

    assert_not result, "Should return false for invalid signature"
  end

  test "#verify_signature returns false for empty string signatures" do
    invalid_signature = ""

    result = BulletTrain::OutgoingWebhooks::SignatureVerification.verify_signature(
      @payload,
      invalid_signature,
      @timestamp,
      @secret
    )

    assert_not result, "Should return false for empty string signature"
  end

  test "#verify_signature returns false for nil signatures" do
    invalid_signature = nil

    result = BulletTrain::OutgoingWebhooks::SignatureVerification.verify_signature(
      @payload,
      invalid_signature,
      @timestamp,
      @secret
    )

    assert_not result, "Should return false for nil signature"
  end

  test "#verify_signature returns false for expired timestamps" do
    tolerance_seconds = Rails.configuration.outgoing_webhooks[:event_verification_tolerance_seconds]
    result = BulletTrain::OutgoingWebhooks::SignatureVerification.verify_signature(
      @payload,
      @valid_signature,
      (tolerance_seconds + 5.seconds).from_now.to_i,
      @secret
    )
    assert_not result, "Should return false for expired timestamps"
  end

  test "#verify_signature returns false for future timestamps" do
    tolerance_seconds = Rails.configuration.outgoing_webhooks[:event_verification_tolerance_seconds]
    result = BulletTrain::OutgoingWebhooks::SignatureVerification.verify_signature(
      @payload,
      @valid_signature,
      (tolerance_seconds + 5.seconds).ago.to_i,
      @secret
    )
    assert_not result, "Should return false for future timestamps"
  end

  test "#verify_request verifies a request's signature" do
    mock_request = Struct.new(:headers, :raw_post).new(
      {
        "X-Bullet-Train-Webhook-Signature" => @valid_signature,
        "X-Bullet-Train-Webhook-Timestamp" => @timestamp
      },
      @payload
    )

    result = BulletTrain::OutgoingWebhooks::SignatureVerification.verify_request(
      mock_request,
      @secret
    )

    assert result, "Should verify valid request"
  end

  test "verify_request returns false with missing headers" do
    mock_request = Struct.new(:headers, :raw_post).new(
      {
        # Missing required headers
      },
      @payload
    )

    result = BulletTrain::OutgoingWebhooks::SignatureVerification.verify_request(
      mock_request,
      @secret
    )

    assert_not result, "Should fail with missing headers"
  end

  test "#generate_signature generates a valid signature that can be verified" do
    payload_hash = {"test" => "data2"}

    signature_data = BulletTrain::OutgoingWebhooks::SignatureVerification.generate_signature(
      payload_hash,
      @secret
    )

    assert signature_data[:signature].present?, "Should generate a signature"
    assert signature_data[:timestamp].present?, "Should generate a timestamp"

    # Verify the generated signature works
    result = BulletTrain::OutgoingWebhooks::SignatureVerification.verify_signature(
      payload_hash.to_json,
      signature_data[:signature],
      signature_data[:timestamp],
      @secret
    )

    assert result, "Generated signature should be verifiable"
  end
end
