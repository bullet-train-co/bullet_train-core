require "test_helper"

class Webhooks::Outgoing::UriFilteringTest < ActiveSupport::TestCase
  class DummyModel
    include Webhooks::Outgoing::UriFiltering

    def cache_key_with_version
      "dummy"
    end

    def to_global_id
      "dummy_id"
    end

    def persisted?
      true
    end
  end

  def assert_allowed_uri(uri)
    m = DummyModel.new
    assert(m.allowed_uri?(URI.parse(uri)))
  end

  def refute_allowed_uri(uri)
    m = DummyModel.new
    refute(m.allowed_uri?(URI.parse(uri)))
  end

  test "allowed_uri?" do
    assert_allowed_uri("http://www.example.com")
    assert_allowed_uri("https://www.example.com")
    assert_allowed_uri("http://104.16.16.194")

    refute_allowed_uri("http://localhost")
    refute_allowed_uri("http://LOCALHOST")
    refute_allowed_uri("telnet://www.example.com")

    refute_allowed_uri("http://192.168.1.1")
    refute_allowed_uri("http://10.0.0.1")
    refute_allowed_uri("http://172.16.0.1")
    refute_allowed_uri("http://100.64.1.1")
    refute_allowed_uri("http://127.0.0.1")
    refute_allowed_uri("http://169.254.169.254")
    refute_allowed_uri("http://[fd12:3456:789a:1::1]")
    refute_allowed_uri("http://[::1]")
  end
end
