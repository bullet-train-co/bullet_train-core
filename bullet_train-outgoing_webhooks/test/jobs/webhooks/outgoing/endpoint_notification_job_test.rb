require "test_helper"

class Webhooks::Outgoing::EndpointNotificationJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

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
      team: @team
    )
  end

  test "performs deactivation_limit_reached notification" do
    assert_emails 1 do
      Webhooks::Outgoing::EndpointNotificationJob.perform_now(
        endpoint_id: @endpoint.id,
        notification_type: "deactivation_limit_reached"
      )
    end
  end

  test "performs deactivated notification" do
    assert_emails 1 do
      Webhooks::Outgoing::EndpointNotificationJob.perform_now(
        endpoint_id: @endpoint.id,
        notification_type: "deactivated"
      )
    end
  end

  test "handles missing endpoint gracefully" do
    assert_no_emails do
      Webhooks::Outgoing::EndpointNotificationJob.perform_now(
        endpoint_id: 999999,
        notification_type: "deactivation_limit_reached"
      )
    end
  end

  test "ignores unknown notification types" do
    assert_no_emails do
      Webhooks::Outgoing::EndpointNotificationJob.perform_now(
        endpoint_id: @endpoint.id,
        notification_type: "unknown_type"
      )
    end
  end
end
