require "test_helper"

# `model` composes with the rest of the routing DSL. Everything it draws — including the
# shallow member routes and the nesting it reopens for children — stays inside whatever
# scope the declaration was made in.
class BulletTrain::Routes::ScopesTest < BulletTrain::Routes::TestCase
  test "inside a namespace" do
    set = draw do
      namespace :account do
        model "Project" do
          model "Projects::Deliverable"
        end
      end
    end

    assert_equal 16, set.routes.count
    assert_recognizes_route set, "account/projects/deliverables#index", :get, "/account/projects/1/deliverables"
    assert_recognizes_route set, "account/projects/deliverables#show", :get, "/account/projects/deliverables/2"
    assert_path set, "/account/projects/deliverables/2", :account_projects_deliverable_path, 2
  end

  test "inside two levels of namespace" do
    set = draw do
      namespace :api do
        namespace :v1 do
          model "Projects::Deliverable" do
            model "Objective"
          end
        end
      end
    end

    assert_recognizes_route set, "api/v1/objectives#index", :get, "/api/v1/projects/deliverables/1/objectives"
    assert_recognizes_route set, "api/v1/objectives#show", :get, "/api/v1/objectives/2"
    assert_path set, "/api/v1/objectives/2", :api_v1_objective_path, 2
  end

  test "a deep chain inside a namespace" do
    set = draw do
      namespace :account do
        model "Form" do
          model "Forms::FieldSet" do
            model "Forms::Field" do
              model "Forms::Fields::Option"
            end
          end
        end
      end
    end

    assert_equal 32, set.routes.count
    assert_recognizes_route set, "account/forms/fields/options#index", :get, "/account/forms/fields/3/options"
    assert_recognizes_route set, "account/forms/fields/options#show", :get, "/account/forms/fields/options/4"
  end

  test "inside scope module" do
    set = draw do
      scope module: :account do
        model "Project" do
          model "Projects::Deliverable"
        end
      end
    end

    # `scope module:` changes the controller but not the URL, exactly as it does for `resources`.
    assert_recognizes_route set, "account/projects/deliverables#index", :get, "/projects/1/deliverables"
    assert_recognizes_route set, "account/projects/deliverables#show", :get, "/projects/deliverables/2"
  end

  test "inside scope path" do
    set = draw do
      scope path: "account" do
        model "Project" do
          model "Projects::Deliverable"
        end
      end
    end

    assert_recognizes_route set, "projects/deliverables#index", :get, "/account/projects/1/deliverables"
    assert_recognizes_route set, "projects/deliverables#show", :get, "/account/projects/deliverables/2"
  end

  test "inside scope as" do
    set = draw do
      scope as: :admin do
        model "Projects::Deliverable" do
          model "Objective"
        end
      end
    end

    assert_path set, "/projects/deliverables/1/objectives", :admin_projects_deliverable_objectives_path, 1
    assert_path set, "/objectives/2", :admin_objective_path, 2
  end

  test "inside constraints" do
    set = draw do
      constraints subdomain: "api" do
        model "Projects::Deliverable" do
          model "Objective"
        end
      end
    end

    set.routes.each do |route|
      assert_equal "api", route.constraints[:subdomain], "expected #{route.path.spec} to keep the subdomain constraint"
    end
  end

  test "inside defaults" do
    set = draw do
      defaults format: :json do
        model "Project" do
          model "Projects::Deliverable"
        end
      end
    end

    set.routes.each do |route|
      assert_equal :json, route.defaults[:format], "expected #{route.path.spec} to default to JSON"
    end
  end

  test "inside a concern, applied in two namespaces" do
    set = draw do
      concern :has_deliverables do
        model "Project" do
          model "Projects::Deliverable"
        end
      end

      namespace :account do
        concerns :has_deliverables
      end

      namespace :admin do
        concerns :has_deliverables
      end
    end

    assert_equal 32, set.routes.count
    assert_recognizes_route set, "account/projects/deliverables#show", :get, "/account/projects/deliverables/1"
    assert_recognizes_route set, "admin/projects/deliverables#show", :get, "/admin/projects/deliverables/1"
  end

  test "a model inside a plain resources block nests under it" do
    set = draw do
      resources :teams do
        model "Projects::Deliverable"
      end
    end

    # No `model` parent, so this is drawn where it was written, like `resources` would be.
    assert_recognizes_route set, "projects/deliverables#index", :get, "/teams/1/projects/deliverables"
    assert_recognizes_route set, "projects/deliverables#show", :get, "/teams/1/projects/deliverables/2"
  end

  test "a model inside a scope within another model's block is drawn there" do
    set = draw do
      model "Project" do
        namespace :extra do
          model "Deliverable"
        end
      end
    end

    # The developer opened a scope, so the model is drawn inside it rather than being
    # hoisted out as a shallow child — the same routes `resources :deliverables` would get.
    assert_recognizes_route set, "extra/deliverables#index", :get, "/projects/1/extra/deliverables"
    assert_recognizes_route set, "extra/deliverables#show", :get, "/projects/1/extra/deliverables/2"
  end

  test "a model inside plain resources within another model's block nests under them" do
    set = draw do
      model "Site" do
        resources :pages do
          model "Hosting::Record"
        end
      end
    end

    assert_recognizes_route set, "hosting/records#index", :get, "/sites/1/pages/2/hosting/records"
    assert_recognizes_route set, "hosting/records#show", :get, "/sites/1/pages/2/hosting/records/3"
  end

  test "naming the namespace in the model gets shallow routes instead" do
    set = draw do
      model "Project" do
        model "Extra::Deliverable"
      end
    end

    assert_recognizes_route set, "extra/deliverables#index", :get, "/projects/1/extra/deliverables"
    assert_recognizes_route set, "extra/deliverables#show", :get, "/extra/deliverables/2"
  end

  test "two independent trees in one route file" do
    set = draw do
      model "Project" do
        model "Projects::Deliverable"
      end

      model "Orders::Fulfillment" do
        model "Shipping::Package"
      end
    end

    assert_equal 32, set.routes.count
    assert_recognizes_route set, "projects/deliverables#show", :get, "/projects/deliverables/1"
    assert_recognizes_route set, "shipping/packages#show", :get, "/shipping/packages/2"
  end

  test "a surrounding namespace composes with the model's own namespace" do
    set = draw do
      namespace :account do
        model "Account::Site"
      end
    end

    # The developer asked for both, so they get both — same as
    # `namespace :account { namespace :account { resources :sites } }`.
    assert_recognizes_route set, "account/account/sites#show", :get, "/account/account/sites/1"
  end
end
