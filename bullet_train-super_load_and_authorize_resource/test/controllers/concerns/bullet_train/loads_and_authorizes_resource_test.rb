require "test_helper"

# Has to be required here because these tests get run in the context of another application in another repo.
require "minitest/mock"
require "ostruct"
class BulletTrain::LoadsAndAuthorizeResourceTest < ActiveSupport::TestCase
  class TestControllerClass < ActionController::Base
    include BulletTrain::LoadsAndAuthorizesResource

    attr_accessor :child_object, :current_user, :parent_object, :team

    def self.regex_to_remove_controller_namespace
    end

    def can?(*args)
    end
  end

  module Users
    class TestControllerClass < ActionController::Base
      include BulletTrain::LoadsAndAuthorizesResource

      def self.regex_to_remove_controller_namespace
        /^BulletTrain::LoadsAndAuthorizeResourceTest::/
      end
    end
  end

  test "model_namespace_from_controller_namespace returns an array of modules names based on the classes namespace minus regex_to_remove_controller_namespace" do
    assert_equal ["BulletTrain", "LoadsAndAuthorizeResourceTest"], TestControllerClass.model_namespace_from_controller_namespace
    assert_equal ["Users"], Users::TestControllerClass.model_namespace_from_controller_namespace
  end

  test "it defines .account_load_and_authorize_resource" do
    assert_respond_to TestControllerClass, :account_load_and_authorize_resource
  end

  test "it defines .regex_to_remove_controller_namespace" do
    assert_respond_to TestControllerClass, :regex_to_remove_controller_namespace
  end

  test "it defines #load_team" do
    assert_respond_to TestControllerClass.new, :load_team
  end

  test "#load_team does not set @team if child_object and parent_object are nil" do
    subject = TestControllerClass.new
    subject.child_object = nil
    subject.parent_object = nil

    assert_nil subject.instance_variable_get(:@team)
  end

  test "#load_team sets @team" do
    team = OpenStruct.new
    subject = TestControllerClass.new
    subject.child_object = OpenStruct.new(team: team)

    subject.load_team

    assert_equal team, subject.instance_variable_get(:@team)
  end

  test "#load_team sets Current attributes if defined" do
    unless defined?(::Current)
      temp_current_class = Class.new(ActiveSupport::CurrentAttributes) do
        attribute :team
      end
      Object.const_set(:Current, temp_current_class)
    end

    team = OpenStruct.new
    subject = TestControllerClass.new
    subject.child_object = OpenStruct.new(team: team)

    team.stub(:try, nil) do
      subject.load_team
    end

    assert_equal team, Current.team

    if temp_current_class
      Object.send(:remove_const, :Current)
    end
  end

  test "#load_team updates current_user's current_team if persisted and can" do
    current_user = Minitest::Mock.new
    team = OpenStruct.new(id: 1)
    subject = TestControllerClass.new
    subject.child_object = OpenStruct.new(team: team)
    subject.current_user = current_user

    current_user.expect(:update_column, nil, [:current_team_id, team.id])

    team.stub(:try, true) do
      subject.stub(:can?, true) do
        subject.load_team
      end
    end

    current_user.verify
  end
end
