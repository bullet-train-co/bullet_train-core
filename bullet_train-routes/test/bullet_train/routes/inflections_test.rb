require "test_helper"

# `model` pluralizes the model's own name to get its collection, exactly as `resources`
# would. It never guesses at the developer's namespaces: whatever module they wrote is the
# module their controller lives in, so irregular and uncountable nouns can't change the
# shape of the routes.
class BulletTrain::Routes::InflectionsTest < BulletTrain::Routes::TestCase
  test "an irregular plural" do
    set = draw do
      model "Person" do
        model "People::Address"
      end
    end

    assert_recognizes_route set, "people/addresses#index", :get, "/people/1/addresses"
    assert_recognizes_route set, "people/addresses#show", :get, "/people/addresses/2"
  end

  test "an irregular plural the developer spelled differently" do
    set = draw do
      model "Person" do
        model "Persons::Address"
      end
    end

    # `Persons::Address` is a different class from `People::Address`, so it keeps its own
    # module rather than being quietly rewritten.
    assert_recognizes_route set, "persons/addresses#index", :get, "/people/1/persons/addresses"
    assert_recognizes_route set, "persons/addresses#show", :get, "/persons/addresses/2"
  end

  test "a chain of irregular plurals" do
    set = draw do
      model "Person" do
        model "People::Child" do
          model "People::Children::Toy"
        end
      end
    end

    assert_recognizes_route set, "people/children#index", :get, "/people/1/children"
    assert_recognizes_route set, "people/children/toys#index", :get, "/people/children/2/toys"
    assert_recognizes_route set, "people/children/toys#show", :get, "/people/children/toys/3"
  end

  test "a plural that is a different word" do
    set = draw do
      model "Datum" do
        model "Data::Point"
      end
    end

    assert_recognizes_route set, "data/points#index", :get, "/data/1/points"
    assert_recognizes_route set, "data/points#show", :get, "/data/points/2"
  end

  test "an uncountable model name" do
    set = draw do
      model "Information" do
        model "Information::Detail"
      end
    end

    assert_recognizes_route set, "information/details#index", :get, "/information/1/details"
    assert_recognizes_route set, "information/details#show", :get, "/information/details/2"
  end

  test "an uncountable model whose namespace the developer pluralized anyway" do
    set = draw do
      model "Information" do
        model "Informations::Detail"
      end
    end

    assert_recognizes_route set, "informations/details#index", :get, "/information/1/informations/details"
    assert_recognizes_route set, "informations/details#show", :get, "/informations/details/2"
  end

  test "a model whose plural is itself, used as its own namespace" do
    set = draw do
      model "Series" do
        model "Series::Episode"
      end
    end

    assert_recognizes_route set, "series/episodes#index", :get, "/series/1/episodes"
    assert_recognizes_route set, "series/episodes#show", :get, "/series/episodes/2"
  end

  test "an already-plural model name" do
    set = draw do
      model "Settings" do
        model "Settings::Notification"
      end
    end

    assert_recognizes_route set, "settings/notifications#index", :get, "/settings/1/notifications"
    assert_recognizes_route set, "settings/notifications#show", :get, "/settings/notifications/2"
  end

  test "an uncountable child under a normal parent" do
    set = draw do
      model "Project" do
        model "Projects::Equipment"
      end
    end

    assert_recognizes_route set, "projects/equipment#index", :get, "/projects/1/equipment"
    assert_recognizes_route set, "projects/equipment#show", :get, "/projects/equipment/2"
  end

  test "an acronym namespace with stock inflections" do
    set = draw do
      model "API::Token" do
        model "API::Scope"
      end
    end

    # Without an acronym rule, `API` underscores to `api` — the same thing
    # `namespace :api { resources :tokens }` produces by hand.
    assert_recognizes_route set, "api/tokens#show", :get, "/api/tokens/1"
    assert_recognizes_route set, "api/scopes#index", :get, "/api/tokens/1/scopes"
  end

  test "a registered acronym" do
    with_isolated_inflections do |inflect|
      inflect.acronym "API"
    end

    set = draw do
      model "APIToken" do
        model "APITokens::Scope"
      end
    end

    assert_recognizes_route set, "api_tokens#show", :get, "/api_tokens/1"
    assert_recognizes_route set, "api_tokens/scopes#index", :get, "/api_tokens/1/scopes"
    assert_recognizes_route set, "api_tokens/scopes#show", :get, "/api_tokens/scopes/2"
  end

  test "a custom irregular inflection" do
    with_isolated_inflections do |inflect|
      inflect.irregular "cactus", "cacti"
    end

    set = draw do
      model "Cactus" do
        model "Cacti::Spine"
      end
    end

    assert_recognizes_route set, "cacti/spines#index", :get, "/cacti/1/spines"
    assert_recognizes_route set, "cacti/spines#show", :get, "/cacti/spines/2"
  end

  test "multi-word model names" do
    set = draw do
      model "LineItem" do
        model "LineItems::Tax"
      end
    end

    assert_recognizes_route set, "line_items/taxes#index", :get, "/line_items/1/taxes"
    assert_recognizes_route set, "line_items/taxes#show", :get, "/line_items/taxes/2"
  end

  test "names with digits" do
    set = draw do
      model "V2::Token" do
        model "V2::Scope"
      end
    end

    assert_recognizes_route set, "v2/tokens#show", :get, "/v2/tokens/1"
    assert_recognizes_route set, "v2/scopes#index", :get, "/v2/tokens/1/scopes"
  end

  test "a model name that is already underscored" do
    assert_same_routes(
      proc { model "Projects::Deliverable" },
      proc { model "projects/deliverable" }
    )
  end

  private

  # Inflections are global, so swap in a copy for the duration of the test and put the
  # original back afterwards. Teardown runs even when an assertion fails.
  def with_isolated_inflections
    store = ActiveSupport::Inflector::Inflections.instance_variable_get(:@__instance__)
    @original_inflections ||= store[:en]
    store[:en] = Marshal.load(Marshal.dump(@original_inflections))

    ActiveSupport::Inflector.inflections(:en) { |inflect| yield inflect }
  end

  def teardown
    if @original_inflections
      ActiveSupport::Inflector::Inflections.instance_variable_get(:@__instance__)[:en] = @original_inflections
    end

    super
  end
end
