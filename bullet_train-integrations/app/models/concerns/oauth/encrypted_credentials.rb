# Keeps provider secrets out of the plaintext `data` payload.
#
# Providers assign the whole OmniAuth hash with `self.data = auth`, which lands
# an access token in a plaintext column where any read of the table returns live,
# replayable credentials.
#
# OmniAuth's schema splits that payload into `info` — normalized, documented
# profile fields — and `credentials`/`extra`. Only `info` is safe to leave in the
# clear, so this concern relocates the other two into encrypted columns. That is
# a whitelist on purpose: `extra` is the provider's raw response and strategies
# put whatever they like in it, so any list of known-secret key names would be
# wrong the moment a strategy invents a new one. Real examples today —
# omniauth-apple puts a bearer JWT in `extra.raw_info.id_token`,
# omniauth-google-oauth2 puts one in `extra.id_token` and falls back to the raw
# access token when the provider returns no id_token, and OAuth1 strategies put a
# live token object there whose instance variables serialize straight into jsonb.
#
# `data` keeps `provider`, `uid` and `info`, so SQL json path lookups and
# functional indexes against profile fields keep working. Anything you need to
# query out of `extra` has to be denormalized into its own column.
#
# Requires `credentials` and `extra` columns and Active Record Encryption keys
# (`bin/rails db:encryption:init`).
module Oauth::EncryptedCredentials
  extend ActiveSupport::Concern

  ENCRYPTED_SUBTREES = %w[credentials extra].freeze

  included do
    encrypts :credentials
    encrypts :extra

    # Catches what the writer below can't see: rows written before this concern
    # was added, and in-place mutation of `data` (which never calls a writer).
    before_save :relocate_encrypted_subtrees
  end

  # Splitting at assignment rather than only on save means a caller reading the
  # token between `data = auth` and `save` gets the new one, not the previous.
  def data=(value)
    super
    relocate_encrypted_subtrees
  end

  # Falls back to a payload still sitting in `data` — a record built but not yet
  # saved, or a row written before this concern existed.
  def credentials
    super.presence || pending_subtree_in_data("credentials")
  end

  def extra
    super.presence || pending_subtree_in_data("extra")
  end

  private

  def pending_subtree_in_data(subtree)
    payload = read_attribute(:data)
    return {} unless payload.is_a?(Hash)

    payload[subtree].is_a?(Hash) ? payload[subtree] : {}
  end

  def relocate_encrypted_subtrees
    # Without the columns, `encrypts` still declares attributes that go nowhere —
    # so this has to check the table, not `has_attribute?`, which they satisfy.
    # Relocating in that state would strip the subtree out of `data` and drop it
    # on the floor; leaving the payload alone keeps it readable until the
    # migration that adds the columns has run.
    return unless ENCRYPTED_SUBTREES.all? { |subtree| self.class.column_names.include?(subtree) }

    payload = read_attribute(:data)
    return unless payload.is_a?(Hash)

    remaining = payload

    ENCRYPTED_SUBTREES.each do |subtree|
      next unless remaining.key?(subtree)

      value = remaining[subtree]
      remaining = remaining.except(subtree)

      # An explicit assignment wins over whatever is still in `data`, so a caller
      # refreshing a token doesn't silently lose it to a stale payload.
      next if attribute_changed?(subtree)

      write_attribute(subtree, value) if value.present?
    end

    write_attribute(:data, remaining) unless remaining.equal?(payload)
  end
end
