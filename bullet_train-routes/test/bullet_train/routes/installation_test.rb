require "test_helper"

# The DSL has to exist by the time `config/routes.rb` is evaluated. The dummy app's route
# file uses `model`, so booting the app at all proves the install happened early enough —
# but assert it directly too, because this is the one failure that takes down the whole app.
class BulletTrain::Routes::InstallationTest < ActiveSupport::TestCase
  test "the mapper extension is installed" do
    assert_includes ActionDispatch::Routing::Mapper.ancestors, BulletTrain::Routes::MapperExtensions
  end

  test "the routing DSL responds to model" do
    mapper = ActionDispatch::Routing::Mapper.new(ActionDispatch::Routing::RouteSet.new)

    assert_respond_to mapper, :model
  end

  test "installing twice is a no-op" do
    refute BulletTrain::Routes.install, "expected a second install to report that it did nothing"
  end

  test "the dummy app drew its model routes while booting" do
    routes = Rails.application.routes.routes.map do |route|
      "#{route.verb} #{route.path.spec}"
    end

    assert_includes routes, "GET /projects/:project_id/deliverables(.:format)"
    assert_includes routes, "GET /projects/deliverables/:id(.:format)"
    assert_includes routes, "GET /account/forms/field_sets/:id(.:format)"
  end

  test "the dummy app's route helpers work" do
    helpers = Rails.application.routes.url_helpers

    assert_equal "/projects/1/deliverables", helpers.project_deliverables_path(1)
    assert_equal "/projects/deliverables/2", helpers.projects_deliverable_path(2)
    assert_equal "/objectives/3", helpers.objective_path(3)
    assert_equal "/account/forms/field_sets/4", helpers.account_forms_field_set_path(4)
  end

  test "drawing the app's routes again is idempotent" do
    before = Rails.application.routes.routes.count

    Rails.application.reload_routes!

    assert_equal before, Rails.application.routes.routes.count
  end

  test "it has a version number" do
    assert BulletTrain::Routes::VERSION
  end
end
