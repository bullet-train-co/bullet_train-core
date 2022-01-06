# frozen_string_literal: true

require_relative "roles/version"

require_relative "../models/role"
require_relative "../roles/permit"
require_relative "../roles/support"

module Roles
  class Error < StandardError; end
end
