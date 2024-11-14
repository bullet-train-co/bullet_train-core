require "test_helper"
require "scaffolding/routes_file_manipulator"

class Scaffolding::RoutesFileManipulatorTest < ActiveSupport::TestCase
  def subject = Scaffolding::RoutesFileManipulator

  def example_file = "test/lib/scaffolding/examples/example._rb"

  def test_file = "tmp/test_routes._rb"

  setup do
    if File.exist?(test_file)
      FileUtils.rm(test_file)
    end
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

  {
    # namespace :account
    109 => 226
  }.each do |starting_line_number, ending_line_number|
    test "find_block_end returns #{ending_line_number} for #{starting_line_number}" do
      results = subject.new(example_file, "Something", "Nothing")
      results = Scaffolding::BlockManipulator.find_block_end(starting_from: starting_line_number, lines: results.lines)
      assert_equal ending_line_number, results
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

  test "apply adds 'Example' within 'Team' appropriately" do
    manipulator = subject.new(example_file, "Example", "Team")
    manipulator.apply(["account"])
    assert_equal File.readlines("test/lib/scaffolding/examples/result_2._rb"), manipulator.lines
  end

  test "apply adds 'Sample' under 'Membership' that appropriately" do
    manipulator = subject.new(example_file, "Sample", "Membership")
    manipulator.apply(["account"])
    assert_equal File.readlines("test/lib/scaffolding/examples/result_3._rb"), manipulator.lines
  end

  test "apply adds 'Webhooks::Outgoing::Log' under 'Webhooks::Outgoing::Event' that appropriately" do
    manipulator = subject.new(example_file, "Webhooks::Outgoing::Log", "Webhooks::Outgoing::Event")
    manipulator.apply(["account"])
    assert_equal File.readlines("test/lib/scaffolding/examples/result_6._rb"), manipulator.lines
  end

  test "apply adds 'Teams::Log' under 'Team' appropriately" do
    manipulator = subject.new(example_file, "Teams::Log", "Team")
    manipulator.apply(["account"])
    assert_equal File.readlines("test/lib/scaffolding/examples/result_4._rb"), manipulator.lines
  end

  test "apply adds 'Webhooks::Log' under 'Webhooks::Outgoing::Event' appropriately" do
    manipulator = subject.new(example_file, "Webhooks::Log", "Webhooks::Outgoing::Event")
    manipulator.apply(["account"])
    assert_equal File.readlines("test/lib/scaffolding/examples/result_5._rb"), manipulator.lines
  end

  test "apply adds the sortable concern properly" do
    manipulator = subject.new(example_file, "Example", "Team", {"sortable" => true})
    manipulator.apply(["account"])
    assert_equal File.readlines("test/lib/scaffolding/examples/result_7._rb"), manipulator.lines
  end

  test "apply gets nested models and namespaces correct" do
    # TODO: Is there a better way to test this? I couldn't figure out how to make multiple calls to `apply` do the right thing.
    # Writing the results of each `apply` to a file and then proceeding is the only thing that seems to work.
    FileUtils.cp example_file, test_file

    manipulator = subject.new(test_file, "Project", "Team", {})
    manipulator.apply(["account"])
    Scaffolding::FileManipulator.write(test_file, manipulator.lines)

    manipulator = subject.new(test_file, "Projects::Milestone", "Project", {})
    manipulator.apply(["account"])
    Scaffolding::FileManipulator.write(test_file, manipulator.lines)

    manipulator = subject.new(test_file, "Projects::Milestones::IncludedTask", "Projects::Milestone", {"sortable" => true})
    manipulator.apply(["account"])
    Scaffolding::FileManipulator.write(test_file, manipulator.lines)

    assert_equal File.readlines("test/lib/scaffolding/examples/result_8._rb"), manipulator.lines

    FileUtils.rm(test_file)
  end

  test "apply adds the activity concern to a new resource" do
    manipulator = subject.new(example_file, "Book", "Team")
    manipulator.add_concern(:activity)
    manipulator.apply(["account"])
    test_line = manipulator.lines.find { |line| line.include?("books") }
    assert test_line.include?("concerns: [:activity]")
  end

  test "apply adds a concern to an existing resource" do
    manipulator = subject.new(example_file, "Book", "Team")
    manipulator.apply(["account"])
    line_number = manipulator.apply(["account"])
    manipulator.add_concern_at_line(:activity, line_number)
    assert_equal manipulator.lines[line_number].squish, "resources :books, concerns: [:activity]"
  end

  test "apply adds a new concern to an existing resource with concerns" do
    manipulator = subject.new(example_file, "Book", "Team")
    line_number = manipulator.apply(["account"])
    # fake an existing concern already added to this resource
    line = manipulator.lines[line_number]
    line = line.squish + ", concerns: [:sortable]\n"
    manipulator.lines[line_number] = line
    manipulator.add_concern_at_line(:activity, line_number)
    assert_equal "resources :books, concerns: [:sortable, :activity]", manipulator.lines[line_number].squish
  end

  test "apply adds a concern to an existing route with existing concerns and a block" do
    manipulator = subject.new(example_file, "Book", "Team")
    line_number = manipulator.apply(["account"])
    # fake an existing concern already added to this resource
    line = manipulator.lines[line_number]
    line = line.squish + ", concerns: [:sortable] do\n"
    manipulator.lines[line_number] = line
    manipulator.add_concern_at_line(:activity, line_number)
    assert_equal "resources :books, concerns: [:sortable, :activity] do", manipulator.lines[line_number].squish
  end

  test "apply adds a concern to an existing route with a block" do
    manipulator = subject.new(example_file, "Book", "Team")
    line_number = manipulator.apply(["account"])
    # fake the start of a block for this resource
    line = manipulator.lines[line_number]
    line = line.squish + " do\n"
    manipulator.lines[line_number] = line
    manipulator.add_concern_at_line(:activity, line_number)
    assert_equal "resources :books, concerns: [:activity] do", manipulator.lines[line_number].squish
  end

  test "apply won't add a concern if it already exists" do
    manipulator = subject.new(example_file, "Book", "Team")
    line_number = manipulator.apply(["account"])
    # fake an existing concern already added to this resource
    line = manipulator.lines[line_number]
    line = line.squish + ", concerns: [:sortable]\n"
    manipulator.lines[line_number] = line
    manipulator.add_concern_at_line(:sortable, line_number)
    assert_equal "resources :books, concerns: [:sortable]", manipulator.lines[line_number].squish
  end
end
