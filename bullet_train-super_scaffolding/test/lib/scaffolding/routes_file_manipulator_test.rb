require "test_helper"
require "scaffolding/routes_file_manipulator"

class Scaffolding::RoutesFileManipulatorTest < ActiveSupport::TestCase
  def subject = Scaffolding::RoutesFileManipulator

  def example_file = "test/lib/scaffolding/examples/example._rb"

  def test_file = "tmp/test_routes._rb"

  # Routes get drawn two ways: with the `model` DSL from `bullet_train-routes`, which is the
  # default, and with hand-written Rails routing, which `--rails-routes` preserves. Both are
  # pinned here against their own fixtures — the `--rails-routes` fixtures are the same bytes
  # they have always been — so neither can regress unnoticed.
  MODES = {
    "the model DSL" => {options: {}, suffix: "_model"},
    "--rails-routes" => {options: {"rails-routes" => true}, suffix: ""}
  }.freeze

  setup do
    if File.exist?(test_file)
      FileUtils.rm(test_file)
    end
  end

  def result_file(number, suffix)
    "test/lib/scaffolding/examples/result_#{number}#{suffix}._rb"
  end

  # In the `model` DSL a resource is declared by model name, so the line the manipulator writes
  # (and that the concern helpers rewrite) reads differently in each mode.
  def book_declaration(suffix)
    (suffix == "_model") ? 'model "Book"' : "resources :books"
  end

  test "initializes" do
    subject.new(example_file, "CuriousKid", ["ProtectiveParent", "Team"])
  end

  {
    ["Scaffolding::Thing", "Scaffolding::Widget"] =>
      ["scaffolding"],

    ["Scaffolding::SomethingTogether::Thing", "Scaffolding::SomethingTogether::Widget"] =>
      ["scaffolding", "something_together"],

    ["Scaffolding::SomethingTogether::Thing", "Scaffolding::SomethingElse::Widget"] =>
      ["scaffolding"]
  }.each do |inputs, outputs|
    test "common_namespaces returns #{outputs} for `#{inputs.first}` under `#{inputs.last}`" do
      results = subject.new(example_file, *inputs).common_namespaces
      assert_equal outputs, results
    end
  end

  {
    ["Scaffolding::Thing", "Scaffolding::Widget"] =>
      [[], "things", [], "widgets"],

    ["Scaffolding::SomethingTogether::Thing", "Scaffolding::SomethingTogether::Widget"] =>
      [[], "things", [], "widgets"],

    ["Scaffolding::SomethingTogether::Thing", "Scaffolding::SomethingElse::Widget"] =>
      [["something_together"], "things", ["something_else"], "widgets"]
  }.each do |inputs, outputs|
    test "divergent_parts returns #{outputs} for `#{inputs.first}` under `#{inputs.last}`" do
      results = subject.new(example_file, *inputs).divergent_parts
      assert_equal outputs, results
    end
  end

  {
    ["webhooks", "incoming"] => {"webhooks" => 46, "incoming" => 47}
  }.each do |inputs, outputs|
    test "find_namespaces at the root level returns #{outputs} for `#{inputs.first}` under `#{inputs.last}`" do
      results = subject.new(example_file, nil, nil).find_namespaces(inputs)
      assert_equal outputs, results
    end
  end

  test "find_or_create_namespaces adds ['account', 'testing', 'example'] appropriately" do
    manipulator = subject.new(example_file, "Something", "Nothing")
    manipulator.find_or_create_namespaces(["account", "testing", "example"])
    assert_equal File.readlines("test/lib/scaffolding/examples/result_1._rb"), manipulator.lines
  end

  test "find_resource_block finds ['account', 'teams'] appropriately" do
    manipulator = subject.new(example_file, "Something", "Nothing")
    assert_equal 143, manipulator.find_resource_block(["account", "teams"])
  end

  test "find_resource_block does not find ['account', 'asdf']" do
    manipulator = subject.new(example_file, "Something", "Nothing")
    assert_nil manipulator.find_resource(["account", "asdf"])
  end

  test "find_resource finds ['account', 'teams'] appropriately" do
    manipulator = subject.new(example_file, "Something", "Nothing")
    assert_equal 143, manipulator.find_resource(["account", "teams"])
  end

  test "find_resource does not find ['account', 'asdf']" do
    manipulator = subject.new(example_file, "Something", "Nothing")
    assert_nil manipulator.find_resource(["account", "asdf"])
  end

  test "a parent that can't be expressed as a model falls back to Rails routing, and says so" do
    model_dsl = subject.new(example_file, "Webhooks::Log", "Webhooks::Outgoing::Event", {})
    model_dsl.apply(["account"])
    assert model_dsl.rails_routes_fallback, "expected the manipulator to report that it fell back"

    requested = subject.new(example_file, "Webhooks::Log", "Webhooks::Outgoing::Event", {"rails-routes" => true})
    requested.apply(["account"])
    assert_nil requested.rails_routes_fallback, "expected no fallback to be reported when Rails routing was asked for"

    assert_equal requested.lines, model_dsl.lines
  end

  test "a model parent is converted into a block to nest under" do
    manipulator = subject.new(example_file, "Example", "Team", {})
    manipulator.apply(["account"])

    # The parent was declared `resources :teams do` before the DSL; a `model` child nested inside
    # a plain `resources` block would be drawn there instead of shallowly, so the declaration is
    # rewritten in place.
    declarations = manipulator.lines.map(&:squish)
    assert_includes declarations, 'model "Team" do'

    # Only the `account` declaration is converted. The one in the `api` namespace belongs to a
    # different base namespace and is left alone.
    before = File.readlines(example_file).map(&:squish).count("resources :teams do")
    assert_equal before - 1, declarations.count("resources :teams do")
  end

  MODES.each do |mode, config|
    options = config[:options]
    suffix = config[:suffix]

    test "apply adds 'Example' within 'Team' appropriately with #{mode}" do
      manipulator = subject.new(example_file, "Example", "Team", options)
      manipulator.apply(["account"])
      assert_equal File.readlines(result_file(2, suffix)), manipulator.lines
    end

    test "apply adds 'Sample' under 'Membership' appropriately with #{mode}" do
      manipulator = subject.new(example_file, "Sample", "Membership", options)
      manipulator.apply(["account"])
      assert_equal File.readlines(result_file(3, suffix)), manipulator.lines
    end

    test "apply adds 'Teams::Log' under 'Team' appropriately with #{mode}" do
      manipulator = subject.new(example_file, "Teams::Log", "Team", options)
      manipulator.apply(["account"])
      assert_equal File.readlines(result_file(4, suffix)), manipulator.lines
    end

    test "apply adds 'Webhooks::Log' under a namespaced parent with #{mode}" do
      manipulator = subject.new(example_file, "Webhooks::Log", "Webhooks::Outgoing::Event", options)
      manipulator.apply(["account"])

      # `Webhooks::Outgoing::Event` is declared as `namespace :webhooks { namespace :outgoing {
      # resources :events } }`. Nesting a `model` under that would mean hoisting the declaration
      # out of both wrappers, which is a bigger edit than Super Scaffolding should make on its
      # own, so these routes are drawn the Rails way in both modes.
      assert_equal File.readlines(result_file(5, "")), manipulator.lines
    end

    test "apply adds 'Webhooks::Outgoing::Log' under a namespaced parent with #{mode}" do
      manipulator = subject.new(example_file, "Webhooks::Outgoing::Log", "Webhooks::Outgoing::Event", options)
      manipulator.apply(["account"])
      assert_equal File.readlines(result_file(6, "")), manipulator.lines
    end

    test "apply adds the sortable concern properly with #{mode}" do
      manipulator = subject.new(example_file, "Example", "Team", options.merge("sortable" => true))
      manipulator.apply(["account"])
      assert_equal File.readlines(result_file(7, suffix)), manipulator.lines
    end

    test "apply gets nested models and namespaces correct with #{mode}" do
      # TODO: Is there a better way to test this? I couldn't figure out how to make multiple calls to `apply` do the right thing.
      # Writing the results of each `apply` to a file and then proceeding is the only thing that seems to work.
      FileUtils.cp example_file, test_file

      manipulator = subject.new(test_file, "Project", "Team", options)
      manipulator.apply(["account"])
      Scaffolding::FileManipulator.write(test_file, manipulator.lines)

      manipulator = subject.new(test_file, "Projects::Milestone", "Project", options)
      manipulator.apply(["account"])
      Scaffolding::FileManipulator.write(test_file, manipulator.lines)

      manipulator = subject.new(test_file, "Projects::Milestones::IncludedTask", "Projects::Milestone", options.merge("sortable" => true))
      manipulator.apply(["account"])
      Scaffolding::FileManipulator.write(test_file, manipulator.lines)

      assert_equal File.readlines(result_file(8, suffix)), manipulator.lines

      FileUtils.rm(test_file)
    end

    test "applying the same model twice doesn't duplicate it with #{mode}" do
      manipulator = subject.new(example_file, "Example", "Team", options)
      manipulator.apply(["account"])
      once = manipulator.lines.dup

      manipulator.apply(["account"])

      assert_equal once, manipulator.lines
    end

    test "apply adds the activity concern to a new resource with #{mode}" do
      manipulator = subject.new(example_file, "Book", "Team", options)
      manipulator.add_concern(:activity)
      manipulator.apply(["account"])
      test_line = manipulator.lines.find { |line| line.include?(book_declaration(suffix)) }
      assert test_line.include?("concerns: [:activity]")
    end

    test "apply adds a concern to an existing resource with #{mode}" do
      manipulator = subject.new(example_file, "Book", "Team", options)
      manipulator.apply(["account"])
      line_number = manipulator.apply(["account"])
      manipulator.add_concern_at_line(:activity, line_number)
      assert_equal "#{book_declaration(suffix)}, concerns: [:activity]", manipulator.lines[line_number].squish
    end

    test "apply adds a new concern to an existing resource with concerns with #{mode}" do
      manipulator = subject.new(example_file, "Book", "Team", options)
      line_number = manipulator.apply(["account"])
      # fake an existing concern already added to this resource
      line = manipulator.lines[line_number]
      line = line.squish + ", concerns: [:sortable]\n"
      manipulator.lines[line_number] = line
      manipulator.add_concern_at_line(:activity, line_number)
      assert_equal "#{book_declaration(suffix)}, concerns: [:sortable, :activity]", manipulator.lines[line_number].squish
    end

    test "apply adds a concern to an existing route with existing concerns and a block with #{mode}" do
      manipulator = subject.new(example_file, "Book", "Team", options)
      line_number = manipulator.apply(["account"])
      # fake an existing concern already added to this resource
      line = manipulator.lines[line_number]
      line = line.squish + ", concerns: [:sortable] do\n"
      manipulator.lines[line_number] = line
      manipulator.add_concern_at_line(:activity, line_number)
      assert_equal "#{book_declaration(suffix)}, concerns: [:sortable, :activity] do", manipulator.lines[line_number].squish
    end

    test "apply adds a concern to an existing route with a block with #{mode}" do
      manipulator = subject.new(example_file, "Book", "Team", options)
      line_number = manipulator.apply(["account"])
      # fake the start of a block for this resource
      line = manipulator.lines[line_number]
      line = line.squish + " do\n"
      manipulator.lines[line_number] = line
      manipulator.add_concern_at_line(:activity, line_number)
      assert_equal "#{book_declaration(suffix)}, concerns: [:activity] do", manipulator.lines[line_number].squish
    end

    test "apply won't add a concern if it already exists with #{mode}" do
      manipulator = subject.new(example_file, "Book", "Team", options)
      line_number = manipulator.apply(["account"])
      # fake an existing concern already added to this resource
      line = manipulator.lines[line_number]
      line = line.squish + ", concerns: [:sortable]\n"
      manipulator.lines[line_number] = line
      manipulator.add_concern_at_line(:sortable, line_number)
      assert_equal "#{book_declaration(suffix)}, concerns: [:sortable]", manipulator.lines[line_number].squish
    end
  end
end
