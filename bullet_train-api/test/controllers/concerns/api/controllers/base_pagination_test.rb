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

    @page_size = Pagy::DEFAULT[:items]
    @half_page_size = @page_size / 2
    @teams_to_create = @page_size + @half_page_size

    create_list(:team, @teams_to_create)
  end

  teardown do
  end

  test "index can paginate" do
    all_teams = Team.all.order(id: :asc)
    assert_equal @teams_to_create, all_teams.count

    expected_last_item_on_first_page = all_teams[@page_size - 1]
    expected_last_id = expected_last_item_on_first_page.id

    get :index
    assert_equal @page_size, response.parsed_body.length
    last_response_id = response.parsed_body.last["id"]
    assert_equal expected_last_id, last_response_id
    assert_equal last_response_id, response.headers["pagination-next"]

    get :index, params: {after: last_response_id}
    assert_equal @half_page_size, response.parsed_body.length
    assert_nil response.headers["pagination-next"]
  end
end
