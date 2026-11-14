require "test_helper"

class Controllers::BaseTest < ActiveSupport::TestCase
  class TestController < ActionController::Base
    include Controllers::Base
  end

  # sentry-ruby is not a dependency, so an app can have SENTRY_DSN in its
  # environment (copied from another app, or set for a different SDK) without
  # the Sentry constant existing.
  test "set_sentry_context does nothing when SENTRY_DSN is set but Sentry isn't loaded" do
    skip "sentry-ruby is loaded in this environment" if defined?(::Sentry)

    previous_dsn = ENV["SENTRY_DSN"]
    ENV["SENTRY_DSN"] = "https://public@example.ingest.sentry.io/1"

    assert_nil TestController.new.send(:set_sentry_context)
  ensure
    ENV["SENTRY_DSN"] = previous_dsn
  end
end
