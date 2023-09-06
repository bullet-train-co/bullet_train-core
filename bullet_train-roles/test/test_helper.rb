# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require File.expand_path("dummy/config/environment.rb", __dir__)

ENV["RAILS_ROOT"] ||= File.dirname(__FILE__) + "dummy"

require "minitest/autorun"

require "knapsack_pro"

knapsack_pro_adapter = KnapsackPro::Adapters::MinitestAdapter.bind
knapsack_pro_adapter.set_test_helper_path(__FILE__)

require "factory_bot_rails"
