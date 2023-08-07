require "resolv"
require "public_suffix"

module Webhooks::Outgoing::UriFiltering
  extend ActiveSupport::Concern

  # WEBHOOK SECURITY PRIMER
  # =============================================================================
  # Outgoing webhooks can be dangerous. By allowing your users to set
  # up outgoing webhooks, you"re giving them permission to call arbitrary
  # URLs from your server, including URLs that could represent resources
  # internal to your company. Malicious actors can use this permission to
  # examine your infrastructure, call internal APIs, and generally cause
  # havok.

  # This module attempts to block malicious actors with the following algorithm
  #   1. Block anything but http and https requests
  #   2. Block or allow defined hostnames, both regex and strings
  #   3. Block if `custom_block_callback` returns true (args: self, uri)
  #   4. Allow if `custom_allow_callback` returns true (args: self, uri)
  #   5. Resolve the IP associated with the webhook"s host directly from
  #      the authoritative name server for the host"s domain. This IP
  #      is cached for the returned DNS TTL
  #   6. Match the given IP against lists of allowed and blocked cidr ranges.
  #      The blocked list by default includes all of the defined private address
  #      ranges, localhost, the private IPv6 prefix, and the AWS metadata
  #      API endpoint.

  # If at any point a URI is determined to be blocked we call `audit_callback`
  # (args: self, uri) so it can be logged for auditing.

  # We resolve the IP from the authoritative name server directly so we can avoid
  # certain classes of DNS poisoning attacks.

  # Users of this gem are _strongly_ enouraged to add additional cidr ranges
  # and hostnames to the appropriate lists and/or implement `custom_block_callback`.
  # At the very least you should add the public hostname that your
  # application uses to the blocked_hostnames list.

  class AllowedUriValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      uri = URI.parse(value)
      unless record.allowed_uri?(uri)
        record.errors.add attribute, "is not an allowed uri"
      end
    end
  end

  def resolve_ip_from_authoritative(hostname)
    begin
      ip = IPAddr.new(hostname)
      return ip.to_s
    rescue IPAddr::InvalidAddressError
      # this is fine, proceed with resolver path
    end

    cache_key = "#{cache_key_with_version}/uri_ip/#{Digest::SHA2.hexdigest(hostname)}"

    cached = Rails.cache.read(cache_key)
    if cached
      return (cached == "invalid") ? nil : cached
    end

    begin
      # This is sort of a half-recursive DNS resolver.
      # We can't implement a full recursive resolver using just Resolv::DNS so instead
      # this asks a public cache for the NS record for the given domain. Then it asks
      # the authoritative nameserver directly for the address and caches it according
      # to the returned TTL.

      config = Rails.configuration.outgoing_webhooks
      ns_resolver = Resolv::DNS.new(nameserver: config[:public_resolvers])
      ns_resolver.timeouts = 1

      domain = PublicSuffix.domain(hostname)
      authoritative = ns_resolver.getresource(domain, Resolv::DNS::Resource::IN::NS)

      authoritative_resolver = Resolv::DNS.new(nameserver: [authoritative.name.to_s])
      authoritative_resolver.timeouts = 1

      resource = authoritative_resolver.getresource(hostname, Resolv::DNS::Resource::IN::A)
      Rails.cache.write(cache_key, resource.address.to_s, expires_in: resource.ttl, race_condition_ttl: 5)
      resource.address.to_s
    rescue ArgumentError
      Rails.cache.write(cache_key, "invalid", expires_in: 10.minutes, race_condition_ttl: 5)
      nil
    end
  end

  def allowed_uri?(uri)
    unless _allowed_uri?(uri)
      config = Rails.configuration.outgoing_webhooks
      if config[:audit_callback].present?
        config[:audit_callback].call(self, uri)
      end
      return false
    end

    true
  end

  def _allowed_uri?(uri)
    return true unless uri.present?

    config = Rails.configuration.outgoing_webhooks
    hostname = uri.hostname.downcase

    return false unless config[:allowed_schemes].include?(uri.scheme)

    config[:blocked_hostnames].each do |blocked|
      if blocked.is_a?(Regexp)
        return false if blocked.match?(hostname)
      end

      return false if blocked == hostname
    end

    config[:allowed_hostnames].each do |allowed|
      if allowed.is_a?(Regexp)
        return true if allowed.match?(hostname)
      end

      return true if allowed == hostname
    end

    if config[:custom_allow_callback].present?
      return true if config[:custom_allow_callback].call(self, uri)
    end

    if config[:custom_block_callback].present?
      return false if config[:custom_block_callback].call(self, uri)
    end

    resolved_ip = resolve_ip_from_authoritative(hostname)
    return false if resolved_ip.nil?

    begin
      config[:allowed_cidrs].each do |cidr|
        return true if IPAddr.new(cidr).include?(resolved_ip)
      end

      config[:blocked_cidrs].each do |cidr|
        return false if IPAddr.new(cidr).include?(resolved_ip)
      end
    rescue IPAddr::InvalidAddressError
      return false
    end

    true
  end
end
