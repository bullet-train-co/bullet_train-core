require "test_helper"
require "minitest/spec"

require "scaffolding/routes_file_manipulator"

describe Scaffolding::RoutesFileManipulator do
  subject { Scaffolding::RoutesFileManipulator }

  it "initializes" do
    subject.new(example_file, "CuriousKid", ["ProtectiveParent", "Team"])
  end

  let(:example_file) { "test/lib/scaffolding/examples/example._rb" }

  describe "common_namespaces" do
    examples = {

      ["Scaffolding::Thing", "Scaffolding::Widget"] =>
        ["scaffolding"],

      ["Scaffolding::SomethingTogether::Thing", "Scaffolding::SomethingTogether::Widget"] =>
        ["scaffolding", "something_together"],

      ["Scaffolding::SomethingTogether::Thing", "Scaffolding::SomethingElse::Widget"] =>
        ["scaffolding"]

    }

    examples.each do |inputs, outputs|
      it "returns #{outputs} for `#{inputs.first}` under `#{inputs.last}`" do
        results = subject.new(example_file, *inputs).common_namespaces
        assert_equal outputs, results
      end
    end
  end

  # describe 'divergent_namespaces' do
  #   examples = {
  #
  #     ['Scaffolding::Thing', 'Scaffolding::Widget'] =>
  #       [[], []],
  #
  #     ['Scaffolding::SomethingTogether::Thing', 'Scaffolding::SomethingTogether::Widget'] =>
  #       [[], []],
  #
  #     ['Scaffolding::SomethingTogether::Thing', 'Scaffolding::SomethingElse::Widget'] =>
  #       [['something_together'], ['something_else']],
  #
  #   }
  #
  #   examples.each do |inputs, outputs|
  #     it "returns #{outputs.to_s} for `#{inputs.first}` under `#{inputs.last}`" do
  #       results = subject.new(example_file, *inputs).divergent_namespaces
  #       assert_equal outputs, results
  #     end
  #   end
  # end

  describe "divergent_parts" do
    examples = {

      ["Scaffolding::Thing", "Scaffolding::Widget"] =>
        [[], "things", [], "widgets"],

      ["Scaffolding::SomethingTogether::Thing", "Scaffolding::SomethingTogether::Widget"] =>
        [[], "things", [], "widgets"],

      ["Scaffolding::SomethingTogether::Thing", "Scaffolding::SomethingElse::Widget"] =>
        [["something_together"], "things", ["something_else"], "widgets"]

    }

    examples.each do |inputs, outputs|
      it "returns #{outputs} for `#{inputs.first}` under `#{inputs.last}`" do
        results = subject.new(example_file, *inputs).divergent_parts
        assert_equal outputs, results
      end
    end
  end

  describe "find_namespaces" do
    describe "root level" do
      examples = {
        ["webhooks", "incoming"] => {"webhooks" => 46, "incoming" => 47}
      }

      examples.each do |inputs, outputs|
        it "returns #{outputs} for `#{inputs.first}` under `#{inputs.last}`" do
          results = subject.new(example_file, nil, nil).find_namespaces(inputs)
          assert_equal outputs, results
        end
      end
    end
  end

  describe "find_block_end" do
    examples = {
      # namespace :account
      109 => 226
    }

    examples.each do |starting_line_number, ending_line_number|
      it "returns #{ending_line_number} for #{starting_line_number}" do
        results = subject.new(example_file, "Something", "Nothing")
        results = Scaffolding::BlockManipulator.find_block_end(starting_from: starting_line_number, lines: results.lines)
        assert_equal ending_line_number, results
      end
    end
  end

  describe "find_or_create_namespaces" do
    it "adds ['account', 'testing', 'example'] appropriately" do
      manipulator = subject.new(example_file, "Something", "Nothing")
      manipulator.find_or_create_namespaces(["account", "testing", "example"])
      assert_equal File.readlines("test/lib/scaffolding/examples/result_1._rb"), manipulator.lines
    end
  end

  describe "find_resource_block" do
    it "finds ['account', 'teams'] appropriately" do
      manipulator = subject.new(example_file, "Something", "Nothing")
      assert_equal 143, manipulator.find_resource_block(["account", "teams"])
    end
    it "does not find ['account', 'asdf']" do
      manipulator = subject.new(example_file, "Something", "Nothing")
      assert_nil manipulator.find_resource(["account", "asdf"])
    end
  end

  describe "find_resource" do
    it "finds ['account', 'teams'] appropriately" do
      manipulator = subject.new(example_file, "Something", "Nothing")
      assert_equal 143, manipulator.find_resource(["account", "teams"])
    end
    it "does not find ['account', 'asdf']" do
      manipulator = subject.new(example_file, "Something", "Nothing")
      assert_nil manipulator.find_resource(["account", "asdf"])
    end
  end

  describe "apply" do
    it "adds 'Example' within 'Team' appropriately" do
      manipulator = subject.new(example_file, "Example", "Team")
      manipulator.apply(["account"])
      assert_equal File.readlines("test/lib/scaffolding/examples/result_2._rb"), manipulator.lines
    end
    it "adds 'Sample' under 'Membership' that appropriately" do
      manipulator = subject.new(example_file, "Sample", "Membership")
      manipulator.apply(["account"])
      assert_equal File.readlines("test/lib/scaffolding/examples/result_3._rb"), manipulator.lines
    end
    it "adds 'Webhooks::Outgoing::Log' under 'Webhooks::Outgoing::Event' that appropriately" do
      manipulator = subject.new(example_file, "Webhooks::Outgoing::Log", "Webhooks::Outgoing::Event")
      manipulator.apply(["account"])
      assert_equal File.readlines("test/lib/scaffolding/examples/result_6._rb"), manipulator.lines
    end
    it "adds 'Teams::Log' under 'Team' appropriately" do
      manipulator = subject.new(example_file, "Teams::Log", "Team")
      manipulator.apply(["account"])
      assert_equal File.readlines("test/lib/scaffolding/examples/result_4._rb"), manipulator.lines
    end
    it "adds 'Webhooks::Log' under 'Webhooks::Outgoing::Event' appropriately" do
      manipulator = subject.new(example_file, "Webhooks::Log", "Webhooks::Outgoing::Event")
      manipulator.apply(["account"])
      assert_equal File.readlines("test/lib/scaffolding/examples/result_5._rb"), manipulator.lines
    end
    it "adds the sortable concern properly" do
      manipulator = subject.new(example_file, "Example", "Team", {"sortable" => true})
      manipulator.apply(["account"])
      assert_equal File.readlines("test/lib/scaffolding/examples/result_7._rb"), manipulator.lines
    end
    it "adds the activity concern to a new resource" do
      manipulator = subject.new(example_file, "Book", "Team")
      manipulator.add_concern(:activity)
      manipulator.apply(["account"])
      test_line = manipulator.lines.find { |line| line.include?("books") }
      assert test_line.include?("concerns: [:activity]")
    end
    it "adds a concern to an existing resource" do
      manipulator = subject.new(example_file, "Book", "Team")
      manipulator.apply(["account"])
      line_number = manipulator.apply(["account"])
      manipulator.add_concern_at_line(:activity, line_number)
      assert_equal manipulator.lines[line_number].squish, "resources :books, concerns: [:activity]"
    end
    it "adds a new concern to an existing resource with concerns" do
      manipulator = subject.new(example_file, "Book", "Team")
      line_number = manipulator.apply(["account"])
      # fake an existing concern already added to this resource
      line = manipulator.lines[line_number]
      line = line.squish + ", concerns: [:sortable]\n"
      manipulator.lines[line_number] = line
      manipulator.add_concern_at_line(:activity, line_number)
      assert_equal "resources :books, concerns: [:sortable, :activity]", manipulator.lines[line_number].squish
    end
    it "adds a concern to an existing route with existing concerns and a block" do
      manipulator = subject.new(example_file, "Book", "Team")
      line_number = manipulator.apply(["account"])
      # fake an existing concern already added to this resource
      line = manipulator.lines[line_number]
      line = line.squish + ", concerns: [:sortable] do\n"
      manipulator.lines[line_number] = line
      manipulator.add_concern_at_line(:activity, line_number)
      assert_equal "resources :books, concerns: [:sortable, :activity] do", manipulator.lines[line_number].squish
    end
  end
end
