require "test_helper"

class LoadsAndAuthorizeResourceTest < ActiveSupport::TestCase
  class TestClass
    include LoadsAndAuthorizesResource
  end

  test "includes BulletTrain::LoadsAndAuthorizesResource" do
    assert TestClass.ancestors.include? BulletTrain::LoadsAndAuthorizesResource
    assert_respond_to TestClass, :account_load_and_authorize_resource
  end
end
