require "test_helper"

class BulletTrainTest < ActiveSupport::TestCase
  test "it has a version number" do
    assert BulletTrain::VERSION
  end

  test "When HIDE_THINGS is not truthy #scaffolding_things_disabled? returns false" do
    old_hide_things = ENV["HIDE_THINGS"]
    ENV["HIDE_THINGS"] = "false"

    refute scaffolding_things_disabled?
  ensure
    ENV["HIDE_THINGS"] = old_hide_things
  end

  test "When HIDE_THINGS is 'true' #scaffolding_things_disabled? returns true" do
    old_hide_things = ENV["HIDE_THINGS"]
    ENV["HIDE_THINGS"] = "true"

    assert scaffolding_things_disabled?
  ensure
    ENV["HIDE_THINGS"] = old_hide_things
  end
end
