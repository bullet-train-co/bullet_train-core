require "test_helper"

# These are basic defensive tests that will let us know if we accidentally change
# the obfuscation method, which would break any links that people have in the wild.
# If you encounter a failure in these tests you probably DO NOT want to change the
# test to fix it. You most likely want to undo whatever change that cause them to
# start failing. Yes, we are basically testing the implementation here, because it's
# important that we maintain the same implementation over time.
class FakeModel
  include ObfuscatesId

  def id
    42
  end

  def expected_obfuscated_id
    "WjmmMj"
  end
end

# This model simulates a Model.new instance that is not persisted yet.
class FakeModelWithNilId
  include ObfuscatesId

  def id
    nil
  end
end

class BulletTrain::ObfuscatesIdConcernTest < ActiveSupport::TestCase
  test "FakeModel has an id" do
    fake_model = FakeModel.new
    assert_equal 42, fake_model.id
  end

  test "FakeModel has a stable obfuscated_id" do
    fake_model = FakeModel.new
    assert_equal fake_model.expected_obfuscated_id, fake_model.obfuscated_id
  end

  test "FakeModel can accurately decode an id" do
    fake_model = FakeModel.new
    assert_equal fake_model.id, FakeModel.decode_id(fake_model.expected_obfuscated_id)
  end

  test "FakeModelWithNilId returns nil when id is nil" do
    assert_nil FakeModelWithNilId.new.to_param
  end
end
