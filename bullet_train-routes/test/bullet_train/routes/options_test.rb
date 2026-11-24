require "test_helper"

# The README calls `model` an interchangeable substitute for `resources`, so every option
# `resources` takes has to work — on a model with no parent, and on a nested one, where the
# options have to survive being split across the nested and shallow halves.
class BulletTrain::Routes::OptionsTest < BulletTrain::Routes::TestCase
  test "only, on a nested model" do
    set = assert_routes(<<~ROUTES) do
      projects             GET    /projects                          projects#index
      -                    POST   /projects                          projects#create
      new_project          GET    /projects/new                      projects#new
      edit_project         GET    /projects/:id/edit                 projects#edit
      project              GET    /projects/:id                      projects#show
      -                    PATCH  /projects/:id                      projects#update
      -                    PUT    /projects/:id                      projects#update
      -                    DELETE /projects/:id                      projects#destroy
      project_deliverables GET    /projects/:project_id/deliverables projects/deliverables#index
      projects_deliverable GET    /projects/deliverables/:id         projects/deliverables#show
    ROUTES
      model "Project" do
        model "Projects::Deliverable", only: [:index, :show]
      end
    end

    refute_recognizes_route set, :post, "/projects/1/deliverables"
    refute_recognizes_route set, :get, "/projects/1/deliverables/new"
  end

  test "only, with nothing in it" do
    set = draw do
      model "Project" do
        model "Projects::Deliverable", only: []
      end
    end

    assert_equal 8, set.routes.count
    assert_empty set.routes.select { |route| route.requirements[:controller] == "projects/deliverables" }
  end

  test "except, on a nested model" do
    set = draw do
      model "Project" do
        model "Projects::Deliverable", except: [:destroy]
      end
    end

    assert_recognizes_route set, "projects/deliverables#show", :get, "/projects/deliverables/1"
    refute_recognizes_route set, :delete, "/projects/deliverables/1"
  end

  test "only, on a model with no parent" do
    set = draw do
      model "Projects::Deliverable", only: [:index]
    end

    assert_equal 1, set.routes.count
    assert_recognizes_route set, "projects/deliverables#index", :get, "/projects/deliverables"
  end

  test "path, on a nested model" do
    set = draw do
      model "Project" do
        model "Projects::Deliverable", path: "items"
      end
    end

    assert_recognizes_route set, "projects/deliverables#index", :get, "/projects/1/items"
    assert_recognizes_route set, "projects/deliverables#show", :get, "/projects/items/2"
  end

  test "path, on a parent, carries into the child's nesting" do
    set = draw do
      model "Project", path: "jobs" do
        model "Projects::Deliverable"
      end
    end

    assert_recognizes_route set, "projects#show", :get, "/jobs/1"
    assert_recognizes_route set, "projects/deliverables#index", :get, "/jobs/1/deliverables"
    assert_recognizes_route set, "projects/deliverables#show", :get, "/projects/deliverables/2"
  end

  test "as, on a nested model" do
    set = draw do
      model "Project" do
        model "Projects::Deliverable", as: :tasks
      end
    end

    assert_path set, "/projects/1/deliverables", :project_tasks_path, 1
    assert_path set, "/projects/deliverables/2", :projects_task_path, 2
  end

  test "as, on a parent, carries into the child's nesting" do
    set = draw do
      model "Project", as: :jobs do
        model "Projects::Deliverable"
      end
    end

    assert_path set, "/projects/1", :job_path, 1
    assert_path set, "/projects/1/deliverables", :job_deliverables_path, 1
  end

  test "param, on a parent, renames the nested segment" do
    set = draw do
      model "Project", param: :uuid do
        model "Projects::Deliverable"
      end
    end

    assert_includes route_table(set), "project GET /projects/:uuid projects#show"
    assert_includes route_table(set), "project_deliverables GET /projects/:project_uuid/deliverables projects/deliverables#index"
  end

  test "param, on a nested model" do
    set = draw do
      model "Project" do
        model "Projects::Deliverable", param: :slug
      end
    end

    assert_includes route_table(set), "projects_deliverable GET /projects/deliverables/:slug projects/deliverables#show"
  end

  test "module, on a nested model" do
    set = draw do
      model "Project" do
        model "Projects::Deliverable", module: :internal
      end
    end

    assert_recognizes_route set, "projects/internal/deliverables#index", :get, "/projects/1/deliverables"
    assert_recognizes_route set, "projects/internal/deliverables#show", :get, "/projects/deliverables/2"
  end

  test "controller, on a nested model" do
    set = draw do
      model "Project" do
        model "Projects::Deliverable", controller: "/custom"
      end
    end

    assert_recognizes_route set, "custom#index", :get, "/projects/1/deliverables"
    assert_recognizes_route set, "custom#show", :get, "/projects/deliverables/2"
  end

  test "concerns, on a nested model, are drawn once" do
    set = draw do
      concern :sortable do
        collection do
          post :sort
        end
      end

      model "Project" do
        model "Projects::Deliverable", concerns: [:sortable]
      end
    end

    sort_routes = route_table(set).grep(/#sort/)

    assert_equal ["sort_project_deliverables POST /projects/:project_id/deliverables/sort projects/deliverables#sort"], sort_routes
  end

  test "constraints, on a nested model" do
    set = draw do
      model "Project" do
        model "Projects::Deliverable", constraints: {subdomain: "admin"}
      end
    end

    deliverable_routes = set.routes.select { |route| route.requirements[:controller] == "projects/deliverables" }

    assert_equal 8, deliverable_routes.count
    deliverable_routes.each do |route|
      assert_equal "admin", route.constraints[:subdomain]
    end
  end

  test "defaults, on a nested model" do
    set = draw do
      model "Project" do
        model "Projects::Deliverable", defaults: {format: :json}
      end
    end

    set.routes.select { |route| route.requirements[:controller] == "projects/deliverables" }.each do |route|
      assert_equal :json, route.defaults[:format]
    end
  end

  test "shallow false opts a child out of shallow member routes" do
    set = draw do
      model "Project" do
        model "Projects::Deliverable", shallow: false
      end
    end

    assert_recognizes_route set, "projects/deliverables#index", :get, "/projects/1/deliverables"
    assert_recognizes_route set, "projects/deliverables#show", :get, "/projects/1/deliverables/2"
    refute_recognizes_route set, :get, "/projects/deliverables/2"
  end

  test "an options hash is not modified" do
    options = {only: [:index]}

    draw do
      model "Project" do
        model "Projects::Deliverable", options
      end
    end

    assert_equal({only: [:index]}, options)
  end

  test "the same options hash can be reused by siblings" do
    options = {only: [:index, :show]}

    set = draw do
      model "Project" do
        model "Projects::Deliverable", options
        model "Projects::Objective", options
      end
    end

    assert_equal 12, set.routes.count
  end
end
