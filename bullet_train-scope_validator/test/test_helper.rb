# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "bullet_train/scope_validator"

require "minitest/autorun"

require_relative "../../test_support/minitest_reporters"
