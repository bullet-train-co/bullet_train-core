require "test_helper"

class BulletTrain::Routes::ArgumentsTest < BulletTrain::Routes::TestCase
  class Deliverable # standin for an app's Projects::Deliverable
  end

  test "a model name as a string" do
    set = draw { model "Projects::Deliverable" }

    assert_recognizes_route set, "projects/deliverables#show", :get, "/projects/deliverables/1"
  end

  test "a model name as a symbol" do
    set = draw { model :deliverable }

    assert_recognizes_route set, "deliverables#show", :get, "/deliverables/1"
  end

  test "a model class" do
    set = draw { model BulletTrain::Routes::ArgumentsTest::Deliverable }

    assert_recognizes_route set, "bullet_train/routes/arguments_test/deliverables#show", :get,
      "/bullet_train/routes/arguments_test/deliverables/1"
  end

  test "a fully qualified model name" do
    assert_same_routes(
      proc { model "Projects::Deliverable" },
      proc { model "::Projects::Deliverable" }
    )
  end

  test "an empty model name is refused" do
    error = assert_raises ArgumentError do
      draw { model "" }
    end

    assert_match "couldn't make a route out of", error.message
  end

  test "a nameless model name is refused" do
    error = assert_raises ArgumentError do
      draw { model "::" }
    end

    assert_match "couldn't make a route out of", error.message
  end

  test "nil is refused" do
    error = assert_raises ArgumentError do
      draw { model nil }
    end

    assert_match "couldn't make a route out of", error.message
  end

  test "a second model name instead of an options hash is refused" do
    error = assert_raises ArgumentError do
      draw { model "Site", "Page" }
    end

    assert_match "options hash as its second argument", error.message
    assert_match "only draws one model at a time", error.message
  end

  test "a third argument is refused" do
    error = assert_raises ArgumentError do
      draw { model "Site", {only: [:index]}, {as: :pages} }
    end

    assert_match "model name and an options hash", error.message
  end

  test "the error message names the model that could not be drawn" do
    error = assert_raises ArgumentError do
      draw { model 42 }
    end

    assert_match "42", error.message
  end

  test "a model with no options behaves like a model with empty options" do
    assert_same_routes(
      proc { model "Projects::Deliverable" },
      proc { model "Projects::Deliverable", {} }
    )
  end
end
