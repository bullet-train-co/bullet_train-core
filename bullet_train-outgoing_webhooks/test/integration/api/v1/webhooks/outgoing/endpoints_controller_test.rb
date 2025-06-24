require "test_helper"

class Api::V1::Webhooks::Outgoing::EndpointsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @controller = Api::V1::Webhooks::Outgoing::EndpointsController

    5.times do |n|
      Team.create! name: "Generic name #{n}"
    end

    5.times do |n|
      Webhooks::Outgoing::Endpoint.create! team_id: Team.first.id, name: "Generic name #{n}", url: "http://example.com/webhook-#{n}"
    end

    @team = Team.first
    @endpoint = @team.webhooks_outgoing_endpoints.first
  end

  test "it returns list of endpoints" do
    get api_v1_team_webhooks_outgoing_endpoints_path(team_id: 1), as: :json

    assert_response :success
    assert_equal 5, response.parsed_body.count
    assert_equal "Generic name 4", response.parsed_body.last["name"]
  end

  test "it returns a single endpoint" do
    get api_v1_webhooks_outgoing_endpoint_path(@endpoint.id), as: :json

    assert_response :success
    assert_equal "Generic name 0", response.parsed_body["name"]
  end

  test "creates endpoints" do
    assert_difference -> { Webhooks::Outgoing::Endpoint.count } do
      post api_v1_team_webhooks_outgoing_endpoints_path(team_id: 1), params: {webhooks_outgoing_endpoint: {name: "Ahoy!", url: "http://example.com/webhook"}}, as: :json
    end

    assert_response :success
    assert_equal Webhooks::Outgoing::Endpoint.last.id, response.parsed_body["id"]
    assert_equal "Ahoy!", Webhooks::Outgoing::Endpoint.last.name
    assert_equal "Ahoy!", response.parsed_body["name"]
    assert_equal "http://example.com/webhook", response.parsed_body["url"]
  end

  test "updates an endpoint" do
    patch api_v1_webhooks_outgoing_endpoint_path(@endpoint.id), params: {webhooks_outgoing_endpoint: {name: "Ahoy!", url: "http://example.com/updated-webhook"}}, as: :json

    assert_response :success
    assert_equal "Ahoy!", Webhooks::Outgoing::Endpoint.find(@endpoint.id).name
    assert_equal "Ahoy!", response.parsed_body["name"]
    assert_equal "http://example.com/updated-webhook", response.parsed_body["url"]
  end

  test "updates allow to update the deactivation fields" do
    assert_not @endpoint.deactivation_limit_reached_at
    assert_not @endpoint.deactivated_at
    assert_equal 0, @endpoint.consecutive_failed_deliveries
    limit_reached_at = 3.days.ago.beginning_of_hour
    deactivated_at = Time.current.beginning_of_hour

    patch api_v1_webhooks_outgoing_endpoint_path(@endpoint.id), params: {
      webhooks_outgoing_endpoint: {
        deactivation_limit_reached_at: limit_reached_at,
        deactivated_at: deactivated_at,
        consecutive_failed_deliveries: 5
      }
    }, as: :json

    assert_response :success
    @endpoint.reload
    assert_equal @endpoint.deactivation_limit_reached_at, limit_reached_at
    assert_equal response.parsed_body["deactivation_limit_reached_at"], limit_reached_at.as_json
    assert_equal @endpoint.deactivated_at, deactivated_at
    assert_equal response.parsed_body["deactivated_at"], deactivated_at.as_json
    assert_equal 5, @endpoint.consecutive_failed_deliveries
    assert_equal 5, response.parsed_body["consecutive_failed_deliveries"]
  end

  test "destroys an endpoint" do
    assert_difference -> { Webhooks::Outgoing::Endpoint.count }, -1 do
      delete api_v1_webhooks_outgoing_endpoint_path(@endpoint.id), as: :json
    end

    assert_response :success
  end
end
