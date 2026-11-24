require "test_helper"

# Every relationship a child model's namespace can have with its parent's.
#
# Two rules cover all of them:
#
#   1. The child's collection actions nest under the parent's canonical path.
#   2. The child's member actions stay at the child's own canonical path.
#
# Namespaces the parent's path already spells out are not repeated in the nested path.
class BulletTrain::Routes::NestingTest < BulletTrain::Routes::TestCase
  test "neither model is namespaced" do
    set = draw do
      model "Site" do
        model "Page"
      end
    end

    assert_equal 16, set.routes.count
    assert_recognizes_route set, "pages#index", :get, "/sites/1/pages"
    assert_recognizes_route set, "pages#show", :get, "/pages/2"
  end

  test "the child is namespaced under the parent's name" do
    set = draw do
      model "Project" do
        model "Projects::Deliverable"
      end
    end

    assert_recognizes_route set, "projects/deliverables#index", :get, "/projects/1/deliverables"
    assert_recognizes_route set, "projects/deliverables#show", :get, "/projects/deliverables/2"
    refute_recognizes_route set, :get, "/projects/1/projects/deliverables/2"
  end

  test "the child is namespaced under the parent's name, with another namespace below it" do
    set = draw do
      model "Project" do
        model "Projects::Internal::Deliverable"
      end
    end

    assert_recognizes_route set, "projects/internal/deliverables#index", :get, "/projects/1/internal/deliverables"
    assert_recognizes_route set, "projects/internal/deliverables#show", :get, "/projects/internal/deliverables/2"
  end

  test "only the child is namespaced" do
    set = draw do
      model "Site" do
        model "Hosting::Page"
      end
    end

    assert_recognizes_route set, "hosting/pages#index", :get, "/sites/1/hosting/pages"
    assert_recognizes_route set, "hosting/pages#show", :get, "/hosting/pages/2"
  end

  test "only the child is namespaced, two segments deep" do
    set = draw do
      model "Site" do
        model "Hosting::Dns::Record"
      end
    end

    assert_recognizes_route set, "hosting/dns/records#index", :get, "/sites/1/hosting/dns/records"
    assert_recognizes_route set, "hosting/dns/records#show", :get, "/hosting/dns/records/2"
  end

  test "only the parent is namespaced" do
    set = draw do
      model "Projects::Deliverable" do
        model "Objective"
      end
    end

    assert_recognizes_route set, "objectives#index", :get, "/projects/deliverables/1/objectives"
    assert_recognizes_route set, "objectives#show", :get, "/objectives/2"
  end

  test "both models are in the same namespace" do
    set = draw do
      model "Projects::Deliverable" do
        model "Projects::Objective"
      end
    end

    # The shared namespace is drawn once, so the child nests under :deliverable_id just as
    # `namespace :projects { resources :deliverables { resources :objectives } }` would.
    assert_recognizes_route set, "projects/objectives#index", :get, "/projects/deliverables/1/objectives"
    assert_recognizes_route set, "projects/objectives#show", :get, "/projects/objectives/2"
    assert_path set, "/projects/deliverables/1/objectives", :projects_deliverable_objectives_path, 1
  end

  test "the child is namespaced under the parent, inside a shared namespace" do
    set = draw do
      model "Projects::Deliverable" do
        model "Projects::Deliverables::Item"
      end
    end

    assert_recognizes_route set, "projects/deliverables/items#index", :get, "/projects/deliverables/1/items"
    assert_recognizes_route set, "projects/deliverables/items#show", :get, "/projects/deliverables/items/2"
  end

  test "the models are in different namespaces" do
    set = draw do
      model "Orders::Fulfillment" do
        model "Shipping::Package"
      end
    end

    assert_recognizes_route set, "shipping/packages#index", :get, "/orders/fulfillments/1/shipping/packages"
    assert_recognizes_route set, "shipping/packages#show", :get, "/shipping/packages/2"
  end

  test "the models share the first of several namespace segments" do
    set = draw do
      model "Common::Projects::Deliverable" do
        model "Common::Objective"
      end
    end

    assert_recognizes_route set, "common/objectives#index", :get, "/common/projects/deliverables/1/objectives"
    assert_recognizes_route set, "common/objectives#show", :get, "/common/objectives/2"
    assert_path set, "/common/projects/deliverables/1/objectives", :common_projects_deliverable_objectives_path, 1
  end

  test "the models share a namespace prefix and the child adds its own" do
    set = draw do
      model "Common::Projects::Deliverable" do
        model "Common::Other::Objective"
      end
    end

    assert_recognizes_route set, "common/other/objectives#index", :get, "/common/projects/deliverables/1/other/objectives"
    assert_recognizes_route set, "common/other/objectives#show", :get, "/common/other/objectives/2"
  end

  test "the models share two namespace segments" do
    set = draw do
      model "Common::Shared::Projects::Deliverable" do
        model "Common::Shared::Objective"
      end
    end

    assert_recognizes_route set, "common/shared/objectives#index", :get, "/common/shared/projects/deliverables/1/objectives"
    assert_recognizes_route set, "common/shared/objectives#show", :get, "/common/shared/objectives/2"
  end

  test "the models have multi-segment namespaces with nothing in common" do
    set = draw do
      model "A::B::Thing" do
        model "C::D::Widget"
      end
    end

    assert_recognizes_route set, "c/d/widgets#index", :get, "/a/b/things/1/c/d/widgets"
    assert_recognizes_route set, "c/d/widgets#show", :get, "/c/d/widgets/2"
  end

  test "the models overlap on a segment that is not a shared prefix" do
    set = draw do
      model "A::B::Thing" do
        model "B::Widget"
      end
    end

    assert_recognizes_route set, "b/widgets#index", :get, "/a/b/things/1/b/widgets"
    assert_recognizes_route set, "b/widgets#show", :get, "/b/widgets/2"
  end

  test "the child is namespaced under the singular parent class" do
    set = draw do
      model "Project" do
        model "Project::Deliverable"
      end
    end

    # `Project::Deliverable` is a different class from `Projects::Deliverable`, so it gets a
    # different controller and a different URL — the module the developer wrote is honored.
    assert_recognizes_route set, "project/deliverables#index", :get, "/projects/1/project/deliverables"
    assert_recognizes_route set, "project/deliverables#show", :get, "/project/deliverables/2"
  end

  test "a model with no parent is drawn at its canonical location" do
    assert_same_routes(
      proc {
        namespace :projects do
          resources :deliverables
        end
      },
      proc {
        model "Projects::Deliverable"
      }
    )
  end

  test "a model with a multi-segment namespace keeps every segment" do
    assert_same_routes(
      proc {
        namespace :a do
          namespace :b do
            namespace :c do
              resources :things
            end
          end
        end
      },
      proc {
        model "A::B::C::Thing"
      }
    )
  end

  test "sibling children are independent of each other" do
    set = draw do
      model "Projects::Deliverable" do
        model "Objective"
        model "Shipping::Package"
      end
    end

    assert_recognizes_route set, "objectives#index", :get, "/projects/deliverables/1/objectives"
    assert_recognizes_route set, "objectives#show", :get, "/objectives/2"
    assert_recognizes_route set, "shipping/packages#index", :get, "/projects/deliverables/1/shipping/packages"
    assert_recognizes_route set, "shipping/packages#show", :get, "/shipping/packages/2"
    assert_equal 24, set.routes.count
  end

  test "nesting adds no routes for the parent" do
    with_child = draw do
      model "Projects::Deliverable" do
        model "Objective"
      end
    end

    without_child = draw do
      model "Projects::Deliverable"
    end

    deliverable_routes = ->(set) {
      route_table(set).select { |route| route.include?("projects/deliverables#") }
    }

    assert_equal deliverable_routes.call(without_child), deliverable_routes.call(with_child)
  end
end
