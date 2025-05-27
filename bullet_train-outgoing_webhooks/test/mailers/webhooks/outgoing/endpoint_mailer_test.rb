require "test_helper"

class Webhooks::Outgoing::EndpointMailerTest < ActionMailer::TestCase
  setup do
    @team = Team.create!(name: "Test Team")
    @user = User.create!(
      email: "test@example.com",
      password: "password"
    )
    @team.memberships.create!(user: @user, role_ids: [Role.admin.id])
    @endpoint = Webhooks::Outgoing::Endpoint.create!(
      name: "Test Endpoint",
      url: "https://example.com/webhook",
      team: @team,
      deactivation_limit_reached_at: Time.current
    )
  end

  test "deactivation_limit_reached email" do
    email = Webhooks::Outgoing::EndpointMailer.deactivation_limit_reached(@endpoint)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [@user.email], email.to
    assert_equal email.subject, "Webhook Endpoint Failure Limit Reached - Test Endpoint"
  end
end
