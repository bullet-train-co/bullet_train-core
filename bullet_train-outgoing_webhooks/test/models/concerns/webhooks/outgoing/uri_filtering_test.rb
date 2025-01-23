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
    # TODO: Can we switch back to www.example.com at some point?
    # It seems like something changed in late 2024 or early 2025 about
    # the example.com domain. When using www.example.com this test is failing with this error:
    #
    # Resolv::ResolvError: DNS result has no information for www.example.com
    # /Users/jgreen/.asdf/installs/ruby/3.4.1/lib/ruby/3.4.0/resolv.rb:502:in 'Resolv::DNS#getresource'
    # app/models/concerns/webhooks/outgoing/uri_filtering.rb:81:in 'Webhooks::Outgoing::UriFiltering#resolve_ip_from_authoritative'
    #
    # So, for now, instead of using www.example.com we're using bullettrain.co
    #
    # assert_allowed_uri("http://www.example.com")
    # assert_allowed_uri("https://www.example.com")
    assert_allowed_uri("http://bullettrain.co")
    assert_allowed_uri("https://bullettrain.co")
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
