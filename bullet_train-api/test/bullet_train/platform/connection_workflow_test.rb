require "test_helper"

class BulletTrain::Platform::ConnectionWorkflowTest < ActiveSupport::TestCase
  setup do
    @workflow = BulletTrain::Platform::ConnectionWorkflow.new
    @client_id = SecureRandom.hex
    @team = Team.create!(name: "test team")
    @application = Platform::Application.create!(uid: @client_id, name: "Test application", team: @team)
    @user = User.create!(email: "test@test.com", password: "password", password_confirmation: "password")
    @membership = Membership.create!(user: @user, team: @team, role_ids: [Role.admin.id])
  end

  def params
    {client_id: @client_id, team_id: @team.id, new_installation: true}
  end

  def current_user
    @user
  end

  def request
    OpenStruct.new url: "http://some-return.url"
  end

  def new_user_session_path(params)
    nil
  end

  def redirect_to(path)
    nil
  end

  def authorize!(action, context)
    nil
  end

  test "calling the workflow creates a User and a Membership" do
    assert_difference("User.count", +1) do
      assert_difference("Membership.count", +1) do
        instance_eval(&@workflow)
      end
    end
  end

  test "calling the workflow twice creates only one User and Membership" do
    # We call it once, for the intial connection
    instance_eval(&@workflow)

    # Then on a subsequent connections, we should not create new users
    assert_difference("User.count", 0) do
      assert_difference("Membership.count", 0) do
        instance_eval(&@workflow)
      end
    end
  end
end
