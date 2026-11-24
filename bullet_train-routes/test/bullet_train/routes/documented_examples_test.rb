require "test_helper"

# Every example in the README, and every form from the blog post it cites:
# https://blog.bullettrain.co/nested-namespaced-rails-routing-examples/
class BulletTrain::Routes::DocumentedExamplesTest < BulletTrain::Routes::TestCase
  test "README: Project and Projects::Deliverable nested under it" do
    set = assert_routes(<<~ROUTES) do
      projects                  GET    /projects                          projects#index
      -                         POST   /projects                          projects#create
      new_project               GET    /projects/new                      projects#new
      edit_project              GET    /projects/:id/edit                 projects#edit
      project                   GET    /projects/:id                      projects#show
      -                         PATCH  /projects/:id                      projects#update
      -                         PUT    /projects/:id                      projects#update
      -                         DELETE /projects/:id                      projects#destroy
      project_deliverables      GET    /projects/:project_id/deliverables projects/deliverables#index
      -                         POST   /projects/:project_id/deliverables projects/deliverables#create
      new_project_deliverable   GET    /projects/:project_id/deliverables/new projects/deliverables#new
      edit_projects_deliverable GET    /projects/deliverables/:id/edit    projects/deliverables#edit
      projects_deliverable      GET    /projects/deliverables/:id         projects/deliverables#show
      -                         PATCH  /projects/deliverables/:id         projects/deliverables#update
      -                         PUT    /projects/deliverables/:id         projects/deliverables#update
      -                         DELETE /projects/deliverables/:id         projects/deliverables#destroy
    ROUTES
      model "Project" do
        model "Projects::Deliverable"
      end
    end

    # The three URLs the README promises for this example.
    assert_recognizes_route set, "projects#show", :get, "/projects/1"
    assert_recognizes_route set, "projects/deliverables#index", :get, "/projects/1/deliverables"
    assert_recognizes_route set, "projects/deliverables#show", :get, "/projects/deliverables/2"

    assert_path set, "/projects/1/deliverables", :project_deliverables_path, 1
    assert_path set, "/projects/deliverables/2", :projects_deliverable_path, 2
    assert_path set, "/projects/deliverables/2/edit", :edit_projects_deliverable_path, 2
  end

  test "README: the Project and Projects::Deliverable hard example is equivalent" do
    collection_actions = [:index, :new, :create]

    assert_same_routes(
      proc {
        resources :projects do
          scope module: "projects" do
            resources :deliverables, only: collection_actions
          end
        end

        namespace :projects do
          resources :deliverables, except: collection_actions
        end
      },
      proc {
        model "Project" do
          model "Projects::Deliverable"
        end
      }
    )
  end

  test "README: Projects::Deliverable and Objective nested under it" do
    set = assert_routes(<<~ROUTES) do
      projects_deliverables              GET    /projects/deliverables             projects/deliverables#index
      -                                  POST   /projects/deliverables             projects/deliverables#create
      new_projects_deliverable           GET    /projects/deliverables/new         projects/deliverables#new
      edit_projects_deliverable          GET    /projects/deliverables/:id/edit    projects/deliverables#edit
      projects_deliverable               GET    /projects/deliverables/:id         projects/deliverables#show
      -                                  PATCH  /projects/deliverables/:id         projects/deliverables#update
      -                                  PUT    /projects/deliverables/:id         projects/deliverables#update
      -                                  DELETE /projects/deliverables/:id         projects/deliverables#destroy
      projects_deliverable_objectives    GET    /projects/deliverables/:projects_deliverable_id/objectives objectives#index
      -                                  POST   /projects/deliverables/:projects_deliverable_id/objectives objectives#create
      new_projects_deliverable_objective GET    /projects/deliverables/:projects_deliverable_id/objectives/new objectives#new
      edit_objective                     GET    /objectives/:id/edit               objectives#edit
      objective                          GET    /objectives/:id                    objectives#show
      -                                  PATCH  /objectives/:id                    objectives#update
      -                                  PUT    /objectives/:id                    objectives#update
      -                                  DELETE /objectives/:id                    objectives#destroy
    ROUTES
      model "Projects::Deliverable" do
        model "Objective"
      end
    end

    # The three URLs the README promises for this example.
    assert_recognizes_route set, "projects/deliverables#show", :get, "/projects/deliverables/1"
    assert_recognizes_route set, "objectives#index", :get, "/projects/deliverables/1/objectives"
    assert_recognizes_route set, "objectives#show", :get, "/objectives/2"

    assert_path set, "/projects/deliverables/1/objectives", :projects_deliverable_objectives_path, 1
    assert_path set, "/objectives/2", :objective_path, 2
  end

  test "README: Orders::Fulfillment and Shipping::Package nested under it" do
    set = assert_routes(<<~ROUTES) do
      orders_fulfillments                     GET    /orders/fulfillments            orders/fulfillments#index
      -                                       POST   /orders/fulfillments            orders/fulfillments#create
      new_orders_fulfillment                  GET    /orders/fulfillments/new        orders/fulfillments#new
      edit_orders_fulfillment                 GET    /orders/fulfillments/:id/edit   orders/fulfillments#edit
      orders_fulfillment                      GET    /orders/fulfillments/:id        orders/fulfillments#show
      -                                       PATCH  /orders/fulfillments/:id        orders/fulfillments#update
      -                                       PUT    /orders/fulfillments/:id        orders/fulfillments#update
      -                                       DELETE /orders/fulfillments/:id        orders/fulfillments#destroy
      orders_fulfillment_shipping_packages    GET    /orders/fulfillments/:orders_fulfillment_id/shipping/packages shipping/packages#index
      -                                       POST   /orders/fulfillments/:orders_fulfillment_id/shipping/packages shipping/packages#create
      new_orders_fulfillment_shipping_package GET    /orders/fulfillments/:orders_fulfillment_id/shipping/packages/new shipping/packages#new
      edit_shipping_package                   GET    /shipping/packages/:id/edit     shipping/packages#edit
      shipping_package                        GET    /shipping/packages/:id          shipping/packages#show
      -                                       PATCH  /shipping/packages/:id          shipping/packages#update
      -                                       PUT    /shipping/packages/:id          shipping/packages#update
      -                                       DELETE /shipping/packages/:id          shipping/packages#destroy
    ROUTES
      model "Orders::Fulfillment" do
        model "Shipping::Package"
      end
    end

    # The three URLs the README promises for this example.
    assert_recognizes_route set, "orders/fulfillments#show", :get, "/orders/fulfillments/1"
    assert_recognizes_route set, "shipping/packages#index", :get, "/orders/fulfillments/1/shipping/packages"
    assert_recognizes_route set, "shipping/packages#show", :get, "/shipping/packages/2"

    assert_path set, "/orders/fulfillments/1/shipping/packages", :orders_fulfillment_shipping_packages_path, 1
    assert_path set, "/shipping/packages/2", :shipping_package_path, 2
  end

  test "README: the Interoperability example" do
    set = assert_routes(<<~ROUTES) do
      search_account_sites   GET    /account/sites/search                 account/sites#search
      publish_account_site   POST   /account/sites/:id/publish            account/sites#publish
      account_site_pages     GET    /account/sites/:site_id/pages         account/pages#index
      -                      POST   /account/sites/:site_id/pages         account/pages#create
      new_account_site_page  GET    /account/sites/:site_id/pages/new     account/pages#new
      edit_account_site_page GET    /account/sites/:site_id/pages/:id/edit account/pages#edit
      account_site_page      GET    /account/sites/:site_id/pages/:id     account/pages#show
      -                      PATCH  /account/sites/:site_id/pages/:id     account/pages#update
      -                      PUT    /account/sites/:site_id/pages/:id     account/pages#update
      -                      DELETE /account/sites/:site_id/pages/:id     account/pages#destroy
      sort_account_sites     POST   /account/sites/sort                   account/sites#sort
      account_sites          GET    /account/sites                        account/sites#index
      -                      POST   /account/sites                        account/sites#create
      new_account_site       GET    /account/sites/new                    account/sites#new
      edit_account_site      GET    /account/sites/:id/edit               account/sites#edit
      account_site           GET    /account/sites/:id                    account/sites#show
      -                      PATCH  /account/sites/:id                    account/sites#update
      -                      PUT    /account/sites/:id                    account/sites#update
      -                      DELETE /account/sites/:id                    account/sites#destroy
    ROUTES
      concern :sortable do
        collection do
          post :sort
        end
      end

      namespace :account do
        model "Site", concerns: [:sortable] do
          collection do
            get :search
          end

          member do
            post :publish
          end

          # Even this still works the way you'd expect.
          resources :pages
        end
      end
    end

    assert_path set, "/account/sites/search", :search_account_sites_path
    assert_path set, "/account/sites/1/publish", :publish_account_site_path, 1
    assert_path set, "/account/sites/1/pages", :account_site_pages_path, 1
  end

  test "blog: Site and Page" do
    assert_same_routes(
      proc {
        resources :sites do
          resources :pages, shallow: true
        end
      },
      proc {
        model "Site" do
          model "Page"
        end
      }
    )
  end

  test "blog: Hosting::Site and Hosting::Page" do
    set = assert_routes(<<~ROUTES) do
      hosting_sites         GET    /hosting/sites                    hosting/sites#index
      -                     POST   /hosting/sites                    hosting/sites#create
      new_hosting_site      GET    /hosting/sites/new                hosting/sites#new
      edit_hosting_site     GET    /hosting/sites/:id/edit           hosting/sites#edit
      hosting_site          GET    /hosting/sites/:id                hosting/sites#show
      -                     PATCH  /hosting/sites/:id                hosting/sites#update
      -                     PUT    /hosting/sites/:id                hosting/sites#update
      -                     DELETE /hosting/sites/:id                hosting/sites#destroy
      hosting_site_pages    GET    /hosting/sites/:site_id/pages     hosting/pages#index
      -                     POST   /hosting/sites/:site_id/pages     hosting/pages#create
      new_hosting_site_page GET    /hosting/sites/:site_id/pages/new hosting/pages#new
      edit_hosting_page     GET    /hosting/pages/:id/edit           hosting/pages#edit
      hosting_page          GET    /hosting/pages/:id                hosting/pages#show
      -                     PATCH  /hosting/pages/:id                hosting/pages#update
      -                     PUT    /hosting/pages/:id                hosting/pages#update
      -                     DELETE /hosting/pages/:id                hosting/pages#destroy
    ROUTES
      model "Hosting::Site" do
        model "Hosting::Page"
      end
    end

    # A shared namespace nests under the parent's own id, exactly as the hand-written
    # `namespace :hosting { resources :sites { resources :pages, shallow: true } }` does.
    assert_recognizes_route set, "hosting/pages#index", :get, "/hosting/sites/1/pages"
    assert_recognizes_route set, "hosting/pages#show", :get, "/hosting/pages/2"
  end

  test "blog: Site and Hosting::Page" do
    set = assert_routes(<<~ROUTES) do
      sites                 GET    /sites                            sites#index
      -                     POST   /sites                            sites#create
      new_site              GET    /sites/new                        sites#new
      edit_site             GET    /sites/:id/edit                   sites#edit
      site                  GET    /sites/:id                        sites#show
      -                     PATCH  /sites/:id                        sites#update
      -                     PUT    /sites/:id                        sites#update
      -                     DELETE /sites/:id                        sites#destroy
      site_hosting_pages    GET    /sites/:site_id/hosting/pages     hosting/pages#index
      -                     POST   /sites/:site_id/hosting/pages     hosting/pages#create
      new_site_hosting_page GET    /sites/:site_id/hosting/pages/new hosting/pages#new
      edit_hosting_page     GET    /hosting/pages/:id/edit           hosting/pages#edit
      hosting_page          GET    /hosting/pages/:id                hosting/pages#show
      -                     PATCH  /hosting/pages/:id                hosting/pages#update
      -                     PUT    /hosting/pages/:id                hosting/pages#update
      -                     DELETE /hosting/pages/:id                hosting/pages#destroy
    ROUTES
      model "Site" do
        model "Hosting::Page"
      end
    end

    assert_recognizes_route set, "hosting/pages#index", :get, "/sites/1/hosting/pages"
    assert_recognizes_route set, "hosting/pages#show", :get, "/hosting/pages/2"
  end

  test "blog: Abstract::Concept and Concrete::Thing" do
    set = draw do
      model "Abstract::Concept" do
        model "Concrete::Thing"
      end
    end

    assert_recognizes_route set, "abstract/concepts#show", :get, "/abstract/concepts/1"
    assert_recognizes_route set, "concrete/things#index", :get, "/abstract/concepts/1/concrete/things"
    assert_recognizes_route set, "concrete/things#show", :get, "/concrete/things/2"

    assert_path set, "/abstract/concepts/1/concrete/things", :abstract_concept_concrete_things_path, 1
    assert_path set, "/concrete/things/2", :concrete_thing_path, 2
  end

  test "no route points at a controller the developer did not name" do
    set = draw do
      model "Project" do
        model "Projects::Deliverable" do
          model "Objective"
        end
      end
    end

    controllers = set.routes.map { |route| route.requirements[:controller] }.uniq

    assert_equal ["projects", "projects/deliverables", "objectives"].sort, controllers.sort
  end

  test "every route is named except the create, update and destroy pairs" do
    set = draw do
      model "Project" do
        model "Projects::Deliverable"
      end
    end

    unnamed = set.routes.reject(&:name).map do |route|
      route.requirements[:action]
    end

    assert_equal (["create", "update", "update", "destroy"] * 2).sort, unnamed.sort
  end
end
