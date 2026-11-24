require "test_helper"

# `model` keeps bookkeeping on the mapper while it draws. These tests make sure none of it
# leaks: what one declaration draws can't depend on what was declared before it.
class BulletTrain::Routes::SiblingsTest < BulletTrain::Routes::TestCase
  test "siblings of three different relationship types" do
    set = draw do
      model "Projects::Deliverable" do
        model "Projects::Objective"
        model "Objective"
        model "Shipping::Package"
      end
    end

    assert_equal 32, set.routes.count
    assert_recognizes_route set, "projects/objectives#show", :get, "/projects/objectives/1"
    assert_recognizes_route set, "objectives#show", :get, "/objectives/2"
    assert_recognizes_route set, "shipping/packages#show", :get, "/shipping/packages/3"
  end

  test "declaration order does not change the routes" do
    forwards = draw do
      model "Projects::Deliverable" do
        model "Objective"
        model "Shipping::Package"
      end
    end

    backwards = draw do
      model "Projects::Deliverable" do
        model "Shipping::Package"
        model "Objective"
      end
    end

    assert_equal route_table(forwards).sort, route_table(backwards).sort
  end

  test "a model drawn alone matches the same model drawn after another tree" do
    alone = draw do
      model "Orders::Fulfillment" do
        model "Shipping::Package"
      end
    end

    after = draw do
      model "Form" do
        model "Forms::FieldSet" do
          model "Forms::Field"
        end
      end

      model "Orders::Fulfillment" do
        model "Shipping::Package"
      end
    end

    fulfillment_routes = ->(set) {
      route_table(set).grep(%r{(orders/fulfillments|shipping/packages)#})
    }

    assert_equal fulfillment_routes.call(alone), fulfillment_routes.call(after)
  end

  test "a top-level model is unaffected by a preceding deep chain" do
    set = draw do
      model "Orders::Fulfillment" do
        model "Shipping::Package" do
          model "Tag"
        end
      end

      model "Projects::Note"
    end

    assert_recognizes_route set, "projects/notes#index", :get, "/projects/notes"
    assert_recognizes_route set, "projects/notes#show", :get, "/projects/notes/1"
  end

  test "Rails route precedence still applies to sibling models" do
    set = draw do
      model "Project"
      model "Projects::Deliverable"
    end

    # `/projects/:id` is declared first, so it matches `/projects/deliverables` — the same
    # thing happens with the hand-written equivalent. Declare the deeper model first, or
    # nest it, if you need the collection URL to win.
    assert_includes route_table(set), "projects_deliverables GET /projects/deliverables projects/deliverables#index"
    assert_recognizes_route set, "projects#show", :get, "/projects/deliverables"

    ordered = draw do
      model "Projects::Deliverable"
      model "Project"
    end

    assert_recognizes_route ordered, "projects/deliverables#index", :get, "/projects/deliverables"
  end

  test "a plain resources declaration between two models" do
    set = draw do
      model "Projects::Deliverable" do
        model "Objective"
        resources :tags
        model "Shipping::Package"
      end
    end

    # The block runs inside the model's own namespace, so `tags` lands in `Projects::`,
    # exactly as it would inside a hand-written `namespace :projects` block.
    assert_recognizes_route set, "projects/tags#index", :get, "/projects/deliverables/1/tags"
    assert_recognizes_route set, "objectives#show", :get, "/objectives/2"
    assert_recognizes_route set, "shipping/packages#show", :get, "/shipping/packages/3"
  end

  test "two models that share a namespace at the top level" do
    set = draw do
      model "Projects::Deliverable"
      model "Projects::Objective"
    end

    assert_equal 16, set.routes.count
    assert_recognizes_route set, "projects/deliverables#show", :get, "/projects/deliverables/1"
    assert_recognizes_route set, "projects/objectives#show", :get, "/projects/objectives/2"
  end

  test "two models whose names differ only by namespace" do
    set = draw do
      model "Projects::Note"
      model "Orders::Note"
    end

    assert_recognizes_route set, "projects/notes#show", :get, "/projects/notes/1"
    assert_recognizes_route set, "orders/notes#show", :get, "/orders/notes/2"
  end

  test "a model declared after its own parent, as a sibling" do
    set = draw do
      model "Project"
      model "Projects::Deliverable"
    end

    assert_recognizes_route set, "projects#show", :get, "/projects/1"
    assert_recognizes_route set, "projects/deliverables#show", :get, "/projects/deliverables/2"
  end

  test "sibling parents can nest the same child model" do
    set = draw do
      model "Projects::Deliverable" do
        model "Tag"
      end

      model "Orders::Fulfillment" do
        model "Tag", as: :fulfillment_tags
      end
    end

    assert_recognizes_route set, "tags#index", :get, "/projects/deliverables/1/tags"
    assert_recognizes_route set, "tags#index", :get, "/orders/fulfillments/1/tags"
  end

  test "an exception in a block leaves the mapper usable" do
    set = draw do
      begin
        model "Project" do
          raise "boom"
        end
      rescue RuntimeError
        nil
      end

      model "Projects::Objective"
    end

    assert_recognizes_route set, "projects/objectives#index", :get, "/projects/objectives"
    assert_recognizes_route set, "projects/objectives#show", :get, "/projects/objectives/1"
  end

  test "an exception in a deeply nested block leaves the mapper usable" do
    set = draw do
      begin
        model "Projects::Deliverable" do
          model "Objective" do
            raise "boom"
          end
        end
      rescue RuntimeError
        nil
      end

      model "Orders::Fulfillment"
    end

    assert_recognizes_route set, "orders/fulfillments#show", :get, "/orders/fulfillments/1"
  end

  test "four sibling children under one parent" do
    set = draw do
      model "Projects::Deliverable" do
        model "Objective"
        model "Tag"
        model "Note"
        model "Comment"
      end
    end

    assert_equal 40, set.routes.count

    ["objectives", "tags", "notes", "comments"].each do |controller|
      assert_equal 8, route_table(set).grep(/\b#{controller}#/).count, "expected 8 routes for #{controller}"
    end
  end
end
