require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "changes to email are passed down to memberships" do
    user = User.create!(email: "test@test.com", password: "password", password_confirmation: "password")
    team1 = Team.create!(name: "new test team")
    membership1 = Membership.create!(team: team1, user: user, user_email: user.email)

    team2 = Team.create!(name: "other test team")
    membership2 = Membership.create!(team: team2, user: user, user_email: user.email)

    assert_equal user.email, membership1.user_email
    assert_equal user.email, membership2.user_email

    user.email = "test2@test.com"

    user.save

    membership1.reload
    membership2.reload
    assert_equal user.email, membership1.user_email
    assert_equal user.email, membership2.user_email
  end
end
