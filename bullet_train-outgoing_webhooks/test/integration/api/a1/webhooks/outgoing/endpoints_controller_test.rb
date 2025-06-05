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

  test "destroys an endpoint" do
    assert_difference -> { Webhooks::Outgoing::Endpoint.count }, -1 do
      delete api_v1_webhooks_outgoing_endpoint_path(@endpoint.id), as: :json
    end

    assert_response :success
  end

  test "activates an endpoint" do
    @endpoint.update(deactivated_at: Time.current, deactivation_limit_reached_at: Time.current)
    assert @endpoint.reload.deactivated?
    assert_not_nil @endpoint.deactivation_limit_reached_at

    post activate_api_v1_webhooks_outgoing_endpoint_path(@endpoint.id), as: :json

    assert_response :success
    assert @endpoint.reload.active?
    assert_nil response.parsed_body["deactivated_at"]
    assert_nil @endpoint.reload.deactivation_limit_reached_at
  end

  test "deactivates an endpoint" do
    current_time = Time.current
    @endpoint.update(deactivated_at: nil, deactivation_limit_reached_at: current_time)
    assert @endpoint.reload.active?
    assert_not_nil @endpoint.deactivation_limit_reached_at

    delete deactivate_api_v1_webhooks_outgoing_endpoint_path(@endpoint.id), as: :json

    assert_response :success
    assert @endpoint.reload.deactivated?
    assert_not_nil response.parsed_body["deactivated_at"]
    assert_equal @endpoint.reload.deactivation_limit_reached_at, current_time
  end

  test "activate handles already active endpoint" do
    @endpoint.update(deactivated_at: nil, deactivation_limit_reached_at: Time.current)
    assert @endpoint.reload.active?
    assert_not_nil @endpoint.deactivation_limit_reached_at

    post activate_api_v1_webhooks_outgoing_endpoint_path(@endpoint.id), as: :json

    assert_response :success
    assert @endpoint.reload.active?
    assert_nil response.parsed_body["deactivated_at"]
    assert_nil @endpoint.reload.deactivation_limit_reached_at
  end

  test "deactivate handles already inactive endpoint" do
    current_time = Time.current
    @endpoint.update(deactivated_at: current_time, deactivation_limit_reached_at: current_time)
    assert @endpoint.reload.deactivated?
    assert_not_nil @endpoint.deactivation_limit_reached_at

    delete deactivate_api_v1_webhooks_outgoing_endpoint_path(@endpoint.id), as: :json

    assert_response :success
    assert @endpoint.reload.deactivated?
    assert_not_nil response.parsed_body["deactivated_at"]
    assert_equal @endpoint.reload.deactivation_limit_reached_at, current_time
  end

  test "activate fails with invalid endpoint" do
    # Since the setup hooks always find from Team.first, this test will never raise RecordNotFound
    # Instead we test that a non-existent endpoint ID results in a 404 response
    post activate_api_v1_webhooks_outgoing_endpoint_path(99999), as: :json
    assert_response :not_found
  end

  test "deactivate fails with invalid endpoint" do
    # Since the setup hooks always find from Team.first, this test will never raise RecordNotFound
    # Instead we test that a non-existent endpoint ID results in a 404 response
    delete deactivate_api_v1_webhooks_outgoing_endpoint_path(99999), as: :json
    assert_response :not_found
  end
end
