require "test_helper"

# A `model` block is an ordinary `resources` block: member and collection actions, nested
# resources, concerns and plain verb routes all work. It is evaluated exactly once, no matter
# which half of a nested model's routes it contributes to.
class BulletTrain::Routes::BlocksTest < BulletTrain::Routes::TestCase
  test "a member block on a nested model follows the shallow member path" do
    set = assert_routes(<<~ROUTES) do
      projects                     GET    /projects                           projects#index
      -                            POST   /projects                           projects#create
      new_project                  GET    /projects/new                       projects#new
      edit_project                 GET    /projects/:id/edit                  projects#edit
      project                      GET    /projects/:id                       projects#show
      -                            PATCH  /projects/:id                       projects#update
      -                            PUT    /projects/:id                       projects#update
      -                            DELETE /projects/:id                       projects#destroy
      publish_projects_deliverable POST   /projects/deliverables/:id/publish  projects/deliverables#publish
      project_deliverables         GET    /projects/:project_id/deliverables  projects/deliverables#index
      -                            POST   /projects/:project_id/deliverables  projects/deliverables#create
      new_project_deliverable      GET    /projects/:project_id/deliverables/new projects/deliverables#new
      edit_projects_deliverable    GET    /projects/deliverables/:id/edit     projects/deliverables#edit
      projects_deliverable         GET    /projects/deliverables/:id          projects/deliverables#show
      -                            PATCH  /projects/deliverables/:id          projects/deliverables#update
      -                            PUT    /projects/deliverables/:id          projects/deliverables#update
      -                            DELETE /projects/deliverables/:id          projects/deliverables#destroy
    ROUTES
      model "Project" do
        model "Projects::Deliverable" do
          member do
            post :publish
          end
        end
      end
    end

    assert_path set, "/projects/deliverables/1/publish", :publish_projects_deliverable_path, 1
  end

  test "a collection block on a nested model follows the nested collection path" do
    set = draw do
      model "Project" do
        model "Projects::Deliverable" do
          collection do
            get :search
          end
        end
      end
    end

    assert_equal ["search_project_deliverables GET /projects/:project_id/deliverables/search projects/deliverables#search"],
      route_table(set).grep(/#search/)
  end

  test "member and collection blocks are each drawn once" do
    set = draw do
      model "Project" do
        model "Projects::Deliverable" do
          member do
            post :publish
          end

          collection do
            get :search
          end
        end
      end
    end

    assert_equal 1, route_table(set).grep(/#publish/).count
    assert_equal 1, route_table(set).grep(/#search/).count
  end

  test "a block is evaluated exactly once as Ruby" do
    evaluations = 0

    draw do
      model "Project" do
        model "Projects::Deliverable" do
          evaluations += 1
        end
      end
    end

    assert_equal 1, evaluations
  end

  test "bare verb routes in a block are drawn once" do
    set = draw do
      model "Project" do
        model "Projects::Deliverable" do
          get :ping
          post :pong
        end
      end
    end

    assert_equal 1, route_table(set).grep(/#ping/).count
    assert_equal 1, route_table(set).grep(/#pong/).count
  end

  test "a route with an explicit name in a block does not collide" do
    set = draw do
      model "Project" do
        model "Projects::Deliverable" do
          get :preview, as: :preview
        end
      end
    end

    assert_equal 1, route_table(set).grep(/#preview/).count
  end

  test "nested plain resources hang off the shallow parent" do
    set = draw do
      model "Project" do
        model "Projects::Deliverable" do
          resources :notes
        end
      end
    end

    # `shallow: true` cascades, exactly as it does for hand-written nested resources.
    assert_recognizes_route set, "projects/notes#index", :get, "/projects/deliverables/1/notes"
    assert_recognizes_route set, "projects/notes#show", :get, "/projects/notes/2"
    assert_equal 8, route_table(set).grep(%r{projects/notes#}).count
  end

  test "nested plain resources can opt out of shallow nesting" do
    set = draw do
      model "Project" do
        model "Projects::Deliverable" do
          resources :notes, shallow: false
        end
      end
    end

    assert_recognizes_route set, "projects/notes#show", :get, "/projects/deliverables/1/notes/2"
  end

  test "a model with no parent keeps its block's resources fully nested" do
    set = draw do
      model "Site" do
        resources :pages
      end
    end

    assert_recognizes_route set, "pages#index", :get, "/sites/1/pages"
    assert_recognizes_route set, "pages#show", :get, "/sites/1/pages/2"
  end

  test "an empty block draws nothing extra" do
    with_block = draw do
      model "Project" do
        model "Projects::Deliverable" do
        end
      end
    end

    without_block = draw do
      model "Project" do
        model "Projects::Deliverable"
      end
    end

    assert_equal route_table(without_block), route_table(with_block)
  end

  test "concerns called as a statement inside a block" do
    set = draw do
      concern :sortable do
        collection do
          post :sort
        end
      end

      model "Project" do
        model "Projects::Deliverable" do
          concerns :sortable
        end
      end
    end

    assert_equal 1, route_table(set).grep(/#sort/).count
  end

  test "a grandchild declared in a block is drawn once" do
    set = draw do
      model "Project" do
        model "Projects::Deliverable" do
          model "Objective"
        end
      end
    end

    assert_equal 8, route_table(set).grep(/objectives#/).count
  end

  test "the README's block DSL works on a nested model too" do
    set = draw do
      concern :sortable do
        collection do
          post :sort
        end
      end

      model "Account::Team" do
        model "Account::Site", concerns: [:sortable] do
          collection do
            get :search
          end

          member do
            post :publish
          end

          resources :pages
        end
      end
    end

    assert_path set, "/account/teams/1/sites/search", :search_account_team_sites_path, 1
    assert_path set, "/account/sites/2/publish", :publish_account_site_path, 2
    assert_path set, "/account/sites/2/pages", :account_site_pages_path, 2
    assert_path set, "/account/teams/1/sites/sort", :sort_account_team_sites_path, 1
  end
end
