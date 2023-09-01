require "test_helper"

class BulletTrain::LoadsAndAuthorizeResourceTest < ActiveSupport::TestCase
  class TestClass
    include BulletTrain::LoadsAndAuthorizesResource

    def self.regex_to_remove_controller_namespace
    end
  end

  module Users
    class TestClass
      include BulletTrain::LoadsAndAuthorizesResource

      def self.regex_to_remove_controller_namespace
        /^BulletTrain::LoadsAndAuthorizeResourceTest::/
      end
    end
  end

  test "model_namespace_from_controller_namespace returns an array of modules names based on the classes namespace minus regex_to_remove_controller_namespace" do
    assert_equal ["BulletTrain", "LoadsAndAuthorizeResourceTest"], TestClass.model_namespace_from_controller_namespace
    assert_equal ["Users"], Users::TestClass.model_namespace_from_controller_namespace
  end

  test "it defines .account_load_and_authorize_resource" do
    assert TestClass.respond_to?(:account_load_and_authorize_resource)
  end

  test "it defines .regex_to_remove_controller_namespace" do
    assert TestClass.respond_to?(:regex_to_remove_controller_namespace)
  end

  test "it defines #load_team" do
    assert TestClass.new.respond_to?(:load_team)
  end
end
