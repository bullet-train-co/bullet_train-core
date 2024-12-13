require "test_helper"

class BulletTrain::Platform::ConnectionWorkflowTest < ActiveSupport::TestCase
  setup do
    @workflow = BulletTrain::Platform::ConnectionWorkflow.new
    @client_id = SecureRandom.hex
    @application = Platform::Application.create!(uid: @client_id, name: "Test application")
    @team = Team.create!(name: "test team")
    @user = User.create!(email: "test@test.com", password: "password", password_confirmation: "password")
  end

  def params
    { client_id: @client_id, team_id: @team.id, new_installation: true }
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

  #test "to_proc returns a proc" do
    #assert_equal "Proc", @workflow.to_proc.class.name
  #end

  test "calling the proc creates a User and a Membership" do
    params = {}
    assert_difference('User.count', +1) do
      assert_difference('Membership.count', +1) do
        instance_eval(&@workflow)
      end
    end
  end

  test "calling the proc twice creates only one User and Membership" do
    params = {}
    assert_difference('User.count', +1) do
      assert_difference('Membership.count', +1) do
        instance_eval(&@workflow)
      end
    end

    assert_difference('User.count', 0) do
      assert_difference('Membership.count', 0) do
        instance_eval(&@workflow)
      end
    end
  end
end
