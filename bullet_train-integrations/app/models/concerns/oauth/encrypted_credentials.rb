# Keeps provider access and refresh tokens out of the plaintext `data` payload.
#
# Providers assign the whole OmniAuth hash with `self.data = auth`, and that hash
# carries a `credentials` subtree holding the access token. This concern moves
# that subtree into its own encrypted column on the way to the database, which is
# the one seam every write already passes through — no provider has to remember
# to do it.
#
# Only `credentials` is encrypted. `data` keeps the `info`/`extra` payload so it
# stays queryable with SQL json paths, which apps commonly rely on for provider
# account ids and for functional indexes. Encrypting the whole column would break
# those lookups without protecting any additional secret.
#
# Requires a `credentials` column on the model's table and Active Record
# Encryption keys (`bin/rails db:encryption:init`).
module Oauth::EncryptedCredentials
  extend ActiveSupport::Concern

  included do
    encrypts :credentials

    before_save :extract_credentials_from_data
  end

  # Falls back to the payload still sitting in `data` for records built but not
  # yet saved, since the callback hasn't relocated it at that point and callers
  # do read the token off an unsaved account while verifying a new connection.
  #
  # Note the asymmetry: the fallback only wins when the column is empty. On a
  # persisted account being re-authed, reading between `data = auth` and the save
  # returns the OLD token. Assign `credentials` directly rather than reaching
  # into `data` if you need the new one before saving.
  def credentials
    super.presence || pending_credentials_in_data
  end

  private

  def pending_credentials_in_data
    return {} unless data.respond_to?(:key?) && data.key?("credentials")

    data["credentials"].to_h
  end

  def extract_credentials_from_data
    return if data.blank?
    return unless data.respond_to?(:key?) && data.key?("credentials")

    incoming = data["credentials"]
    self.data = data.to_h.except("credentials")
    self.credentials = incoming.to_h if incoming.present?
  end
end
