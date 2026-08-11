require "test_helper"

class Oauth::EncryptedCredentialsTest < ActiveSupport::TestCase
  # A stand-in for a scaffolded provider account: the same column set
  # `super_scaffold:oauth_provider` now generates.
  class Account < ActiveRecord::Base
    self.table_name = "oauth_encrypted_credentials_test_accounts"
    include Oauth::EncryptedCredentials
  end

  # The same table without the concern, for writing rows the way they looked
  # before it existed.
  class LegacyAccount < ActiveRecord::Base
    self.table_name = "oauth_encrypted_credentials_test_accounts"
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
      t.json :extra
      t.timestamps
    end
  end

  teardown do
    ActiveRecord::Base.connection.drop_table :oauth_encrypted_credentials_test_accounts, if_exists: true
  end

  test "assigning an omniauth payload moves credentials and extra out of data" do
    account = Account.create!(uid: "abc123", data: omniauth_payload).reload

    assert_nil account.data["credentials"]
    assert_nil account.data["extra"]
    assert_equal "sekret-access-token", account.credentials["token"]
    assert_equal "sekret-id-token", account.extra["raw_info"]["id_token"]
    assert_equal "Some User", account.data.dig("info", "name")
  end

  # The reason `extra` is encrypted at all: strategies put bearer tokens in it.
  test "neither subtree is recoverable from the raw database row" do
    account = Account.create!(uid: "abc123", data: omniauth_payload)

    row = ActiveRecord::Base.connection.select_one(
      "SELECT data, credentials, extra FROM oauth_encrypted_credentials_test_accounts WHERE id = #{account.id}"
    )

    refute_includes row["data"].to_s, "sekret-access-token"
    refute_includes row["data"].to_s, "sekret-id-token"
    refute_includes row["credentials"].to_s, "sekret-access-token"
    refute_includes row["extra"].to_s, "sekret-id-token"
  end

  test "info is left queryable in the clear" do
    account = Account.create!(uid: "abc123", data: omniauth_payload)

    row = ActiveRecord::Base.connection.select_one(
      "SELECT data FROM oauth_encrypted_credentials_test_accounts WHERE id = #{account.id}"
    )

    assert_includes row["data"].to_s, "Some User"
  end

  # Callers read the token off an unsaved account while verifying a new connection.
  test "subtrees are readable before the record is saved" do
    account = Account.new(uid: "abc123", data: omniauth_payload)

    assert_equal "sekret-access-token", account.credentials["token"]
    assert_equal "sekret-id-token", account.extra["raw_info"]["id_token"]
  end

  # Splitting at assignment rather than on save is what makes this pass.
  test "a re-auth reads the new token before the save" do
    account = Account.create!(uid: "abc123", data: omniauth_payload)

    account.data = omniauth_payload.merge("credentials" => {"token" => "rotated-token"})

    assert_equal "rotated-token", account.credentials["token"]
  end

  test "an explicit credentials assignment survives the save" do
    account = Account.create!(uid: "abc123", data: omniauth_payload)

    account.data = omniauth_payload
    account.credentials = {"token" => "manually-assigned-token"}
    account.save!

    assert_equal "manually-assigned-token", account.reload.credentials["token"]
  end

  # The callback's guard: on a row whose `data` still carries the subtree, an
  # explicit assignment must not be overwritten from that stale payload.
  test "an explicit assignment beats a payload still sitting in data" do
    legacy = LegacyAccount.create!(uid: "abc123", data: omniauth_payload)

    account = Account.find(legacy.id)
    account.credentials = {"token" => "manually-assigned-token"}
    account.save!

    assert_equal "manually-assigned-token", account.reload.credentials["token"]
  end

  # A row written before this concern was added: token still in `data`, encrypted
  # columns empty. It has to read, and it has to migrate on the next save.
  test "a legacy row reads through the fallback and migrates when saved" do
    legacy = LegacyAccount.create!(uid: "abc123", data: omniauth_payload)

    account = Account.find(legacy.id)
    assert_equal "sekret-access-token", account.credentials["token"]

    account.save!
    account.reload

    assert_nil account.data["credentials"]
    assert_equal "sekret-access-token", account.credentials["token"]

    row = ActiveRecord::Base.connection.select_one(
      "SELECT data FROM oauth_encrypted_credentials_test_accounts WHERE id = #{account.id}"
    )
    refute_includes row["data"].to_s, "sekret-access-token"
  end

  # Mutating `data` in place never calls the writer, so the callback is what
  # catches this one.
  test "mutating data in place still relocates the subtree" do
    account = Account.create!(uid: "abc123", data: {"info" => {"name" => "Some User"}})

    account.data["credentials"] = {"token" => "late-token"}
    account.save!

    assert_equal "late-token", account.reload.credentials["token"]

    row = ActiveRecord::Base.connection.select_one(
      "SELECT data FROM oauth_encrypted_credentials_test_accounts WHERE id = #{account.id}"
    )
    refute_includes row["data"].to_s, "late-token"
  end

  test "credentials are empty rather than nil when the payload carries none" do
    account = Account.create!(uid: "abc123", data: {"info" => {"name" => "Some User"}})

    assert_empty account.reload.credentials
    assert_empty account.extra
  end

  test "a later data write without the subtrees leaves the stored values alone" do
    account = Account.create!(uid: "abc123", data: omniauth_payload)

    account.data = {"info" => {"name" => "Renamed User"}}
    account.save!

    assert_equal "sekret-access-token", account.reload.credentials["token"]
  end

  # A json column can legitimately hold something that isn't a hash.
  test "a non-hash payload is left alone rather than raising" do
    assert_nothing_raised do
      Account.create!(uid: "abc123", data: ["not", "a", "hash"])
      Account.create!(uid: "def456", data: "a string")
      Account.create!(uid: "ghi789", data: nil)
    end

    assert_empty Account.find_by(uid: "def456").credentials
  end

  # Including the concern into a model whose table predates it must not strip the
  # payload out of `data` and drop it into a virtual attribute that goes nowhere.
  test "a table without the columns keeps the payload rather than losing it" do
    ActiveRecord::Base.connection.create_table :oauth_encrypted_credentials_legacy_table, force: true do |t|
      t.string :uid
      t.json :data
      t.timestamps
    end

    unmigrated = Class.new(ActiveRecord::Base) do
      self.table_name = "oauth_encrypted_credentials_legacy_table"
      include Oauth::EncryptedCredentials
    end

    account = unmigrated.create!(uid: "abc123", data: omniauth_payload)

    assert_equal "sekret-access-token", account.reload.data.dig("credentials", "token")
  ensure
    ActiveRecord::Base.connection.drop_table :oauth_encrypted_credentials_legacy_table, if_exists: true
  end

  private

  # Shaped like a real auth hash, including the bearer token that
  # omniauth-apple and omniauth-google-oauth2 place in `extra`.
  def omniauth_payload
    {
      "provider" => "example",
      "uid" => "abc123",
      "info" => {"name" => "Some User", "email" => "user@example.com"},
      "credentials" => {"token" => "sekret-access-token", "refresh_token" => "sekret-refresh-token"},
      "extra" => {"raw_info" => {"id_token" => "sekret-id-token", "account_id" => "acct_123"}}
    }
  end
end
