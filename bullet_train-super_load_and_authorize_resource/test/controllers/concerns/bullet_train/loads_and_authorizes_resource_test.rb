require "test_helper"

class BulletTrain::LoadsAndAuthorizeResourceTest < ActiveSupport::TestCase
  class TestClass
    include BulletTrain::LoadsAndAuthorizesResource
  end

  test "it defines .model_namespace_from_controller_namespace" do
    assert TestClass.respond_to?(:model_namespace_from_controller_namespace)
  end

  test "it defines .account_load_and_authorize_resource" do
    assert TestClass.respond_to?(:account_load_and_authorize_resource)
  end

  test "it defines #load_team" do
    assert TestClass.new.respond_to?(:load_team)
  end

  test "it defines #regex_to_remove_controller_namespace" do
    assert TestClass.new.respond_to?(:regex_to_remove_controller_namespace)
  end
end
