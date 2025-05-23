require "test_helper"
require "minitest/mock"
require "sidekiq/testing"

class Webhooks::Outgoing::EndpointsDeactivationWorkerTest < ActiveSupport::TestCase
  def worker
    Webhooks::Outgoing::EndpointsDeactivationWorker.new
  end

  def endpoint_health_mock
    @endpoint_health_mock ||= Minitest::Mock.new
  end

  def stub_config(config, &block)
    BulletTrain::OutgoingWebhooks::Engine.config.stub(:outgoing_webhooks, config, &block)
  end

  def stub_endpoint_health(&block)
    Webhooks::Outgoing::EndpointHealth.stub(:new, endpoint_health_mock, &block)
  end

  setup do
    @endpoint_health_mock = Minitest::Mock.new # Reset mock for each test
  end

  test "perform does not call EndpointHealth methods when feature is disabled" do
    stub_config({automatic_deactivation_endpoint_enabled: false}) do
      assert_nil worker.perform # early return
    end
  end

  test "perform calls EndpointHealth methods when feature is enabled" do
    stub_config({automatic_deactivation_endpoint_enabled: true}) do
      stub_endpoint_health do
        endpoint_health_mock.expect :deactivate_failed_endpoints!, true
        endpoint_health_mock.expect :mark_to_deactivate!, true

        worker.perform
      end
    end
    endpoint_health_mock.verify
  end
end
