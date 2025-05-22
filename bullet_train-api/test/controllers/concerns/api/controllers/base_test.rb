require "test_helper"

class Api::Controllers::Base::Test < ActionController::TestCase
  class PaginationTestController < ActionController::Base
    include Api::Controllers::Base
    prepend_before_action :load_teams
    def index
      render json: @teams.as_json
    end

    def collection_variable
      "@teams"
    end

    def load_teams
      @teams = Team.all
    end
  end

  setup do
    @controller = Class.new(PaginationTestController).new

    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw do
      get "index" => "anonymous#index"
    end

    create_list(:team, 30)
  end

  teardown do
  end

  test "index can paginate" do
    assert_equal 30, Team.all.count

    get :index
    assert_equal 20, response.parsed_body.length
    last_response_id = response.parsed_body.last["id"]
    assert_equal last_response_id, response.headers["pagination-next"]

    get :index, params: { after: last_response_id }
    assert_equal 10, response.parsed_body.length
    assert_nil response.headers["pagination-next"]
  end

end
