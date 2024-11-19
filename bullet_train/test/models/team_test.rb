require "test_helper"

class TeamTest < ActiveSupport::TestCase
  test "a new team defaults time_zone to UTC" do
    team = Team.new
    assert_equal "UTC", team.time_zone
  end
end
