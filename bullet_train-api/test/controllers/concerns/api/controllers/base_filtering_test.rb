require "test_helper"

class Api::Controllers::Base::FilteringTest < ActionController::TestCase
  class FilteringTestController < ActionController::Base
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

    def apply_filters
      @teams = @teams.where(id: params[:team_id]) if params[:team_id]
    end
  end

  setup do
    @controller = Class.new(FilteringTestController).new

    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw do
      get "index" => "anonymous#index"
    end

    @teams_to_create = 3
    create_list(:team, @teams_to_create)
  end

  teardown do
  end

  test "index can filter" do
    all_teams = Team.all.order(id: :asc)
    assert_equal @teams_to_create, all_teams.count

    get :index
    assert_equal @teams_to_create, response.parsed_body.length

    team = Team.first

    get :index, params: {team_id: team.id}
    assert_equal 1, response.parsed_body.length
  end
end
