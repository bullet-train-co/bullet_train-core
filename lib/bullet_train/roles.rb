# frozen_string_literal: true

require_relative "roles/version"

require_relative "../models/role"
require_relative "../roles/permit"
require_relative "../roles/support"
require_relative "../roles/user"

require_relative "roles/engine" if defined?(Rails)

module Roles
  class Error < StandardError; end
end
