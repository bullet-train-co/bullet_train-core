require "test_helper"

class Api::V1::Webhooks::Outgoing::EndpointsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @controller = Api::V1::Webhooks::Outgoing::EndpointsController
  end

  test "it returns list of endpoints" do
    get api_v1_team_webhooks_outgoing_endpoints_path(team_id: 1), as: :json

    assert_response :success
    assert_equal 5, response.parsed_body.count
    assert_equal "Generic name 4", response.parsed_body.last["name"]
  end

  test "it returns a single endpoint" do
    get api_v1_webhooks_outgoing_endpoint_path(2), as: :json

    assert_response :success
    assert_equal "Generic name 1", response.parsed_body["name"]
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
    patch api_v1_webhooks_outgoing_endpoint_path(3), params: {webhooks_outgoing_endpoint: {name: "Ahoy!", url: "http://example.com/updated-webhook"}}, as: :json

    assert_response :success
    assert_equal "Ahoy!", Webhooks::Outgoing::Endpoint.find(3).name
    assert_equal "Ahoy!", response.parsed_body["name"]
    assert_equal "http://example.com/updated-webhook", response.parsed_body["url"]
  end

  test "destroys an endpoint" do
    assert_difference -> { Webhooks::Outgoing::Endpoint.count }, -1 do
      delete api_v1_webhooks_outgoing_endpoint_path(4), as: :json
    end

    assert_response :success
  end
end
