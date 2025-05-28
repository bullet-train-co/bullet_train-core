require "test_helper"
require "minitest/mock"

class Account::Webhooks::Outgoing::EndpointsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @team = Team.create! name: "Test team"
    @user = User.create!(
      email: "test@example.com",
      password: "password"
    )
    @team.memberships.create!(user: @user, role_ids: [Role.admin.id])
    @user.update!(current_team_id: @team.id)

    @endpoint = Webhooks::Outgoing::Endpoint.create!(
      team_id: @team.id,
      name: "Test Endpoint",
      url: "http://example.com/webhook"
    )

    # this is too hard to mock, so we just stub it out
    Account::Webhooks::Outgoing::EndpointsController.define_method(:ensure_onboarding_is_complete) { true }

    sign_in @user
  end

  test "activate action with POST request" do
    @endpoint.update(deactivated_at: Time.current)
    assert_not @endpoint.active?

    post "/account/webhooks/outgoing/endpoints/#{@endpoint.id}/activate"

    assert_redirected_to "/account/teams/#{@team.id}/webhooks/outgoing/endpoints"
    assert @endpoint.reload.active?
  end

  test "deactivate action with DELETE request" do
    @endpoint.update(deactivated_at: nil)
    assert @endpoint.active?

    delete "/account/webhooks/outgoing/endpoints/#{@endpoint.id}/deactivate"

    assert_redirected_to "/account/teams/#{@team.id}/webhooks/outgoing/endpoints"
    assert_not @endpoint.reload.active?
    assert_not_nil @endpoint.deactivated_at
  end
end
