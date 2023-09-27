require "test_helper"

class Webhooks::Outgoing::Endpoints::SharedSecretSupportTest < ActiveSupport::TestCase
  class DummyModel
    def self.belongs_to(*args)
    end

    def self.has_many(*args)
    end

    def self.scope(*args)
    end

    def secret
      "secret"
    end

    include Webhooks::Outgoing::Endpoints::SharedSecretSupport
  end

  test "generate_signature" do
    now = DateTime.parse("2023-07-11 13:37:00Z")
    m = DummyModel.new

    assert(m.signature_valid?(now.to_i.to_s, "payload", m.generate_signature(now.to_i.to_s, "payload")))
  end
end
