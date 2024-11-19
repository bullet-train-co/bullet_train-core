require "test_helper"

class TeamTest < ActiveSupport::TestCase
  test "a new team defaults time_zone to UTC" do
    team = Team.new
    assert_equal "UTC", team.time_zone
  end

  test "a new team gets the time_zone of the first user when they join" do
    team = Team.create!(name: "new test team")
    user = User.create!(email: "test@test.com", password: "password", password_confirmation: "password", time_zone: "Central Time (US & Canada)")
    Membership.create!(team: team, user: user)
    team.reload
    assert_equal "Central Time (US & Canada)", team.time_zone
  end
end
