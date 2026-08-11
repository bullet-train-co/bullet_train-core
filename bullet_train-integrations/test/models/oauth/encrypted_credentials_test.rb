require "test_helper"

class Oauth::EncryptedCredentialsTest < ActiveSupport::TestCase
  # A stand-in for a scaffolded provider account: the same `data`/`credentials`
  # column pair `super_scaffold:oauth_provider` now generates.
  class Account < ActiveRecord::Base
    self.table_name = "oauth_encrypted_credentials_test_accounts"
    include Oauth::EncryptedCredentials
  end

  setup do
    ActiveRecord::Encryption.configure(
      primary_key: "test_primary_key_000000000000000",
      deterministic_key: "test_deterministic_key_000000000",
      key_derivation_salt: "test_key_derivation_salt_0000000"
    )

    ActiveRecord::Base.connection.create_table :oauth_encrypted_credentials_test_accounts, force: true do |t|
      t.string :uid
      t.json :data
      t.json :credentials
      t.timestamps
    end
  end

  teardown do
    ActiveRecord::Base.connection.drop_table :oauth_encrypted_credentials_test_accounts, if_exists: true
  end

  # The whole point: an OmniAuth hash assigned wholesale must not leave the token
  # sitting in the plaintext column.
  test "assigning an omniauth payload moves credentials out of data" do
    account = Account.create!(uid: "abc123", data: omniauth_payload)
    account.reload

    assert_nil account.data["credentials"]
    assert_equal "sekret-access-token", account.credentials["token"]
    assert_equal "Some User", account.data.dig("info", "name")
  end

  test "the token is not recoverable from the raw database row" do
    account = Account.create!(uid: "abc123", data: omniauth_payload)

    row = ActiveRecord::Base.connection.select_one(
      "SELECT data, credentials FROM oauth_encrypted_credentials_test_accounts WHERE id = #{account.id}"
    )

    refute_includes row["data"].to_s, "sekret-access-token"
    refute_includes row["credentials"].to_s, "sekret-access-token"
  end

  # Callers read the token off an unsaved account while verifying a new connection,
  # before the callback has relocated it.
  test "credentials are readable on an unsaved record" do
    account = Account.new(uid: "abc123", data: omniauth_payload)

    assert_equal "sekret-access-token", account.credentials["token"]
  end

  test "credentials are empty rather than nil when the payload carries none" do
    account = Account.create!(uid: "abc123", data: {"info" => {"name" => "Some User"}})

    assert_empty account.reload.credentials
  end

  # Re-auth has to overwrite the stored token, not keep the first one.
  test "re-assigning a payload replaces the stored credentials" do
    account = Account.create!(uid: "abc123", data: omniauth_payload)

    account.data = omniauth_payload.merge("credentials" => {"token" => "rotated-token"})
    account.save!

    assert_equal "rotated-token", account.reload.credentials["token"]
  end

  test "a payload without a credentials key leaves stored credentials alone" do
    account = Account.create!(uid: "abc123", data: omniauth_payload)

    account.data = {"info" => {"name" => "Renamed User"}}
    account.save!

    assert_equal "sekret-access-token", account.reload.credentials["token"]
  end

  private

  def omniauth_payload
    {
      "provider" => "example",
      "uid" => "abc123",
      "info" => {"name" => "Some User", "email" => "user@example.com"},
      "credentials" => {"token" => "sekret-access-token", "refresh_token" => "sekret-refresh-token"}
    }
  end
end
