require "test_helper"

class BulletTrain::ThemesTest < ActiveSupport::TestCase
  test "it has a version number" do
    assert BulletTrain::Themes::VERSION
  end

  # jbuilder's `json.partial!` renders with an options Hash whose locals hold the
  # JbuilderTemplate itself, and a Jbuilder turns `#hash` into a JSON key that
  # returns nil. Hashing that options Hash for the cache lookup raised
  # "TypeError: no implicit conversion of nil into Integer".
  class UnhashableLikeJbuilder < BasicObject
    def method_missing(*) = nil

    def respond_to_missing?(*) = true
  end

  test "resolved_partial_path_for ignores a render argument that is not a String" do
    # Ruby only hashes a lookup key once the Hash has an entry, so the error only
    # appeared after the process had resolved any theme partial.
    BulletTrain::Themes.partial_paths["shared/__test_entry"] = "themes/base/__test_entry"
    options = {partial: "users/user", locals: {json: UnhashableLikeJbuilder.new}}

    assert_nil BulletTrain::Themes::Base::Theme.new.resolved_partial_path_for(nil, options, {})
  ensure
    BulletTrain::Themes.partial_paths.delete("shared/__test_entry")
  end
end
