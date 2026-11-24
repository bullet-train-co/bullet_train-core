require "test_helper"

# Chains deeper than one level. Each model is drawn exactly once at its own canonical path,
# so a chain's route count grows linearly and no path accumulates a parent's module twice.
class BulletTrain::Routes::DepthTest < BulletTrain::Routes::TestCase
  test "the four-level Super Scaffolding chain" do
    set = assert_routes(<<~ROUTES) do
      forms                     GET    /forms                                     forms#index
      -                         POST   /forms                                     forms#create
      new_form                  GET    /forms/new                                 forms#new
      edit_form                 GET    /forms/:id/edit                            forms#edit
      form                      GET    /forms/:id                                 forms#show
      -                         PATCH  /forms/:id                                 forms#update
      -                         PUT    /forms/:id                                 forms#update
      -                         DELETE /forms/:id                                 forms#destroy
      form_field_sets           GET    /forms/:form_id/field_sets                 forms/field_sets#index
      -                         POST   /forms/:form_id/field_sets                 forms/field_sets#create
      new_form_field_set        GET    /forms/:form_id/field_sets/new             forms/field_sets#new
      edit_forms_field_set      GET    /forms/field_sets/:id/edit                 forms/field_sets#edit
      forms_field_set           GET    /forms/field_sets/:id                      forms/field_sets#show
      -                         PATCH  /forms/field_sets/:id                      forms/field_sets#update
      -                         PUT    /forms/field_sets/:id                      forms/field_sets#update
      -                         DELETE /forms/field_sets/:id                      forms/field_sets#destroy
      forms_field_set_fields    GET    /forms/field_sets/:field_set_id/fields     forms/fields#index
      -                         POST   /forms/field_sets/:field_set_id/fields     forms/fields#create
      new_forms_field_set_field GET    /forms/field_sets/:field_set_id/fields/new forms/fields#new
      edit_forms_field          GET    /forms/fields/:id/edit                     forms/fields#edit
      forms_field               GET    /forms/fields/:id                          forms/fields#show
      -                         PATCH  /forms/fields/:id                          forms/fields#update
      -                         PUT    /forms/fields/:id                          forms/fields#update
      -                         DELETE /forms/fields/:id                          forms/fields#destroy
      forms_field_options       GET    /forms/fields/:field_id/options            forms/fields/options#index
      -                         POST   /forms/fields/:field_id/options            forms/fields/options#create
      new_forms_field_option    GET    /forms/fields/:field_id/options/new        forms/fields/options#new
      edit_forms_fields_option  GET    /forms/fields/options/:id/edit             forms/fields/options#edit
      forms_fields_option       GET    /forms/fields/options/:id                  forms/fields/options#show
      -                         PATCH  /forms/fields/options/:id                  forms/fields/options#update
      -                         PUT    /forms/fields/options/:id                  forms/fields/options#update
      -                         DELETE /forms/fields/options/:id                  forms/fields/options#destroy
    ROUTES
      model "Form" do
        model "Forms::FieldSet" do
          model "Forms::Field" do
            model "Forms::Fields::Option"
          end
        end
      end
    end

    assert_path set, "/forms/field_sets/2", :forms_field_set_path, 2
    assert_path set, "/forms/field_sets/2/fields", :forms_field_set_fields_path, 2
    assert_path set, "/forms/fields/3", :forms_field_path, 3
    assert_path set, "/forms/fields/3/options", :forms_field_options_path, 3
    assert_path set, "/forms/fields/options/4", :forms_fields_option_path, 4
  end

  test "a five-level chain draws eight routes per model and no more" do
    set = draw do
      model "Form" do
        model "Forms::FieldSet" do
          model "Forms::Field" do
            model "Forms::Fields::Option" do
              model "Forms::Fields::Options::Translation"
            end
          end
        end
      end
    end

    assert_equal 40, set.routes.count
    assert_recognizes_route set, "forms/fields/options/translations#index", :get, "/forms/fields/options/4/translations"
    assert_recognizes_route set, "forms/fields/options/translations#show", :get, "/forms/fields/options/translations/5"
  end

  test "a dive edge followed by an ejecting edge" do
    set = draw do
      model "Project" do
        model "Projects::Deliverable" do
          model "Objective"
        end
      end
    end

    assert_equal 24, set.routes.count
    assert_recognizes_route set, "projects/deliverables#index", :get, "/projects/1/deliverables"
    assert_recognizes_route set, "projects/deliverables#show", :get, "/projects/deliverables/2"
    assert_recognizes_route set, "objectives#index", :get, "/projects/deliverables/2/objectives"
    assert_recognizes_route set, "objectives#show", :get, "/objectives/3"
  end

  test "an ejecting edge followed by a plain edge" do
    set = draw do
      model "Projects::Deliverable" do
        model "Objective" do
          model "Task"
        end
      end
    end

    assert_equal 24, set.routes.count
    assert_recognizes_route set, "objectives#index", :get, "/projects/deliverables/1/objectives"
    assert_recognizes_route set, "tasks#index", :get, "/objectives/2/tasks"
    assert_recognizes_route set, "tasks#show", :get, "/tasks/3"
  end

  test "a chain that re-enters a namespace it already left" do
    set = draw do
      model "Projects::Deliverable" do
        model "Objective" do
          model "Projects::Note"
        end
      end
    end

    assert_recognizes_route set, "projects/notes#index", :get, "/objectives/2/projects/notes"
    assert_recognizes_route set, "projects/notes#show", :get, "/projects/notes/3"
  end

  test "a chain in the same namespace all the way down" do
    set = draw do
      model "Hosting::Site" do
        model "Hosting::Page" do
          model "Hosting::Block"
        end
      end
    end

    assert_equal 24, set.routes.count
    assert_recognizes_route set, "hosting/pages#index", :get, "/hosting/sites/1/pages"
    assert_recognizes_route set, "hosting/blocks#index", :get, "/hosting/pages/2/blocks"
    assert_recognizes_route set, "hosting/blocks#show", :get, "/hosting/blocks/3"
  end

  test "an un-namespaced chain matches hand-written shallow resources" do
    assert_same_routes(
      proc {
        resources :sites do
          resources :pages, shallow: true do
            resources :comments, shallow: true
          end
        end
      },
      proc {
        model "Site" do
          model "Page" do
            model "Comment"
          end
        end
      }
    )
  end

  test "deep chains draw no duplicate paths or names" do
    set = draw do
      model "Form" do
        model "Forms::FieldSet" do
          model "Forms::Field" do
            model "Forms::Fields::Option"
          end
        end
      end
    end

    endpoints = set.routes.map { |route| [route.verb.to_s, route.path.spec.to_s] }
    names = set.routes.map(&:name).compact

    assert_equal endpoints.uniq, endpoints
    assert_equal names.uniq, names
  end

  test "deep chains only reference controllers for the models that were declared" do
    set = draw do
      model "Form" do
        model "Forms::FieldSet" do
          model "Forms::Field" do
            model "Forms::Fields::Option"
          end
        end
      end
    end

    expected = ["forms", "forms/field_sets", "forms/fields", "forms/fields/options"]

    assert_equal expected.sort, set.routes.map { |route| route.requirements[:controller] }.uniq.sort
  end

  test "member routes never nest behind more than one id" do
    set = draw do
      model "Form" do
        model "Forms::FieldSet" do
          model "Forms::Field" do
            model "Forms::Fields::Option"
          end
        end
      end
    end

    members = set.routes.select { |route| route.requirements[:action].in?(%w[show edit update destroy]) }

    members.each do |route|
      path = route.path.spec.to_s.sub(/\(\.:format\)\z/, "")

      assert_equal 1, path.scan(/:\w+/).count, "expected one dynamic segment in #{path}"
    end
  end
end
