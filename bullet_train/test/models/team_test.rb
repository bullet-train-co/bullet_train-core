require "test_helper"

# A minimal ActiveRecord model including Records::Base for testing purposes
class TestTeam < ActiveRecord::Base
  self.table_name = "teams"

  include Records::Base

  attr_accessor :name
  attr_accessor :name_was

  def self.label_attribute
    :name
  end
end

class TeamTest < ActiveSupport::TestCase
  test "a new team defaults time_zone to UTC" do
    team = Team.new
    assert_equal "UTC", team.time_zone
  end

  test "explicitly set time_zone is not clobbered by first user" do
    team = Team.create!(name: "new test team", time_zone: "Eastern Time (US & Canada)")
    user = User.create!(email: "test@test.com", password: "password", password_confirmation: "password", time_zone: "Central Time (US & Canada)")
    Membership.create!(team: team, user: user)
    team.reload
    assert_equal "Eastern Time (US & Canada)", team.time_zone
  end

  test "a new team gets the time_zone of the first user when they join" do
    team = Team.create!(name: "new test team")
    user = User.create!(email: "test@test.com", password: "password", password_confirmation: "password", time_zone: "Central Time (US & Canada)")
    Membership.create!(team: team, user: user)
    team.reload
    assert_equal "Central Time (US & Canada)", team.time_zone
  end

  test "a team with a nil time_zone gets the time_zone of the first user when they join" do
    team = Team.create!(name: "new test team")
    team.time_zone = nil
    team.save
    team.reload
    assert_equal nil, team.time_zone

    user = User.create!(email: "test@test.com", password: "password", password_confirmation: "password", time_zone: "Central Time (US & Canada)")
    Membership.create!(team: team, user: user)
    team.reload
    assert_equal "Central Time (US & Canada)", team.time_zone
  end

  test "default UTC time_zone is not clobbered if first user doesn't have a time zone set" do
    team = Team.create!(name: "new test team")
    user = User.create!(email: "test@test.com", password: "password", password_confirmation: "password", time_zone: nil)
    Membership.create!(team: team, user: user)
    team.reload
    assert_equal "UTC", team.time_zone
  end

  test "default UTC time_zone is overwritten once the first user sets a time zone" do
    team = Team.create!(name: "new test team")
    user = User.create!(email: "test@test.com", password: "password", password_confirmation: "password", time_zone: nil)
    Membership.create!(team: team, user: user)
    team.reload
    assert_equal "UTC", team.time_zone

    user.time_zone = "Central Time (US & Canada)"
    user.save

    team.reload
    assert_equal "Central Time (US & Canada)", team.time_zone
  end

  test "nil time_zone is overwritten once the first user sets a time zone" do
    team = Team.create!(name: "new test team", time_zone: nil)
    user = User.create!(email: "test@test.com", password: "password", password_confirmation: "password", time_zone: nil)
    Membership.create!(team: team, user: user)
    team.time_zone = nil
    team.save
    team.reload
    assert_equal nil, team.time_zone

    user.time_zone = "Central Time (US & Canada)"
    user.save

    team.reload
    assert_equal "Central Time (US & Canada)", team.time_zone
  end

  test "#label_string returns the name of the model if name is nil" do
    team = TestTeam.new

    assert_equal "Test Team", team.label_string
  end

  test "#label_string returns the value of #name ('Test Name')" do
    @team = TestTeam.new
    @team.name = "Test Name"

    assert_equal @team.name, @team.label_string # fails, returning nil (the value of name_was)
  end

  test "#label_string returns the value of #name_was if set ('Old Name')" do
    @team = TestTeam.new
    @team.name = "Test Name"

    @team.name_was = "Old Name"
    assert_equal "Old Name", @team.label_string # passes
  end
end
