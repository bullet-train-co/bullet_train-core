# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require "simplecov"
SimpleCov.start

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../test/dummy/db/migrate", __dir__)]
require "rails/test_help"

# Load fixtures from the engine
fixture_path = File.expand_path("fixtures", __dir__)

if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
  ActiveSupport::TestCase.fixture_paths = [fixture_path]
  ActionDispatch::IntegrationTest.fixture_paths = ActiveSupport::TestCase.fixture_paths
  ActiveSupport::TestCase.file_fixture_path = "#{fixture_path}/files"
  ActiveSupport::TestCase.fixtures :all
elsif ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = fixture_path
  ActionDispatch::IntegrationTest.fixture_path = ActiveSupport::TestCase.fixture_path
  ActiveSupport::TestCase.file_fixture_path = "#{fixture_path}/files"
  ActiveSupport::TestCase.fixtures :all
end

require_relative "../../test_support/minitest_reporters"

module BulletTrain
  module Routes
    # Draws routes into a throwaway route set and asserts on what came out.
    #
    # Routes are compared as a table of "name VERB /path controller#action" lines in
    # declaration order, so an assertion fails on an unexpected *extra* route just as
    # loudly as on a missing one. Expected tables are written as heredocs; whitespace
    # between columns is insignificant.
    class TestCase < ActiveSupport::TestCase
      private

      def draw(&block)
        set = ActionDispatch::Routing::RouteSet.new
        set.draw(&block)
        set
      end

      def route_table(set)
        set.routes.map do |route|
          requirements = route.requirements
          endpoint = if requirements[:controller]
            "#{requirements[:controller]}##{requirements[:action]}"
          else
            route.app.inspect
          end

          [
            route.name || "-",
            route.verb.to_s.gsub(/[$^]/, ""),
            route.path.spec.to_s.sub(/\(\.:format\)\z/, ""),
            endpoint
          ].join(" ")
        end
      end

      def assert_routes(expected, &block)
        set = draw(&block)
        assert_equal parse_table(expected), route_table(set)
        set
      end

      # The README's "hard example" blocks are equivalence claims: `model` has to produce the
      # same routes the hand-written version does. Route *order* legitimately differs (we draw
      # a parent's own routes before its children's), so compare the tables as sets.
      def assert_same_routes(expected_block, actual_block)
        expected = route_table(draw(&expected_block)).sort
        actual = route_table(draw(&actual_block)).sort

        assert_equal expected, actual
      end

      # Asks the router what an incoming request would actually match. Unlike
      # `recognize_path` this doesn't need the controller class to exist, so routes can be
      # tested without a controller for every model in the suite.
      def recognize(set, method, path)
        request = ActionDispatch::Request.new(Rack::MockRequest.env_for(path, method: method.to_s.upcase))
        match = nil

        set.router.recognize(request) do |route, params|
          match = {endpoint: "#{params[:controller]}##{params[:action]}", name: route.name, params: params}
          break
        end

        match
      end

      def assert_recognizes_route(set, expected, method, path)
        match = recognize(set, method, path)

        flunk "expected #{method.to_s.upcase} #{path} to route to #{expected}, but it matches no route" unless match
        assert_equal expected, match[:endpoint], "#{method.to_s.upcase} #{path}"

        match
      end

      def refute_recognizes_route(set, method, path)
        match = recognize(set, method, path)

        assert_nil match, "expected #{method.to_s.upcase} #{path} not to route, but it reached #{match && match[:endpoint]}"
      end

      def assert_path(set, expected, name, *arguments)
        helpers = set.url_helpers

        assert helpers.respond_to?(name), "expected the route helper #{name} to be defined"
        assert_equal expected, helpers.public_send(name, *arguments)
      end

      def refute_path_helper(set, name)
        refute set.url_helpers.respond_to?(name), "expected no route helper named #{name}"
      end

      def parse_table(table)
        table.lines.map { |line| line.strip.split(/\s+/).join(" ") }.reject(&:empty?)
      end
    end
  end
end
