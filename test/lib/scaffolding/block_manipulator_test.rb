require "test_helper"
require "minitest/spec"

require "scaffolding/block_manipulator"

describe Scaffolding::BlockManipulator do
  file_path = "./test/lib/scaffolding/examples/block_manipulator_data.html.erb"
  initial_file_contents =
    <<~INITIAL

      <% test_block do %>
        <p>with some content</p>
      <% end %>
    INITIAL

  after :all do
    File.write(file_path, initial_file_contents)
  end

  def initialize_demo_file file_path, data = nil
    File.write(file_path, data)
  end

  it "inserts within a block and after the given location" do
    initial_data =
      <<~INITIAL

        <% test_block do %>
          <p>with some content</p>
        <% end %>

      INITIAL
    initialize_demo_file(file_path, initial_data)
    initial_lines = File.readlines(file_path)

    new_lines = Scaffolding::BlockManipulator.insert("a new string", within: "<% test_block", after: "<p>", lines: initial_lines)
    Scaffolding::FileManipulator.write(file_path, new_lines, strip: false)

    expected_result =
      <<~RESULT

        <% test_block do %>
          <p>with some content</p>
          a new string
        <% end %>

      RESULT
    assert_equal(File.readlines(file_path), new_lines)
    assert_equal(File.read(file_path), expected_result)
  end

  it "inserts into an empty block" do
    initial_data =
      <<~INITIAL

        <% outer_block do %>
          <% inner_block do %>
          <% end %>
        <% end %>

      INITIAL
    initialize_demo_file(file_path, initial_data)
    initial_lines = File.readlines(file_path)

    new_lines = Scaffolding::BlockManipulator.insert("  Some new content", within: "<% inner_block", lines: initial_lines)
    Scaffolding::FileManipulator.write(file_path, new_lines, strip: false)

    expected_result =
      <<~EXPECTED

        <% outer_block do %>
          <% inner_block do %>
            Some new content
          <% end %>
        <% end %>

      EXPECTED
    assert_equal(File.readlines(file_path), new_lines)
    assert_equal(File.read(file_path), expected_result)
  end

  it "inserts content after the given block" do
    initial_data =
      <<~INITIAL

        <% outer_block do %>
          <% inner_block do %>
          <% end %>
        <% end %>

      INITIAL
    initialize_demo_file(file_path, initial_data)
    initial_lines = File.readlines(file_path)

    new_lines = Scaffolding::BlockManipulator.insert("Post content", after_block: "<% inner_block", lines: initial_lines)
    Scaffolding::FileManipulator.write(file_path, new_lines, strip: false)

    expected_result =
      <<~EXPECTED

        <% outer_block do %>
          <% inner_block do %>
          <% end %>
          Post content
        <% end %>

      EXPECTED
    assert_equal(File.readlines(file_path), new_lines)
    assert_equal(File.read(file_path), expected_result)
  end

  it "appends a line after the block" do
    initial_data =
      <<~DATA

        <% test_block do %>
        <% end %>

      DATA
    initialize_demo_file(file_path, initial_data)
    initial_lines = File.readlines(file_path)

    new_lines = Scaffolding::BlockManipulator.insert("This is a new line", after_block: "<% test_block", lines: initial_lines)
    Scaffolding::FileManipulator.write(file_path, new_lines, strip: false)

    expected_result =
      <<~RESULT

        <% test_block do %>
        <% end %>
        This is a new line

      RESULT
    assert_equal(File.readlines(file_path), new_lines)
    assert_equal(File.read(file_path), expected_result)
  end

  it "inserts within an if statement" do
    initial_data =
      <<~INITIAL

        <% if a_test %>
          <p>with some content</p>
        <% end %>

      INITIAL
    initialize_demo_file(file_path, initial_data)
    initial_lines = File.readlines(file_path)

    new_lines = Scaffolding::BlockManipulator.insert("a new string", within: "<% if a_test", after: "<p>", lines: initial_lines)
    Scaffolding::FileManipulator.write(file_path, new_lines, strip: false)

    expected_result =
      <<~RESULT

        <% if a_test %>
          <p>with some content</p>
          a new string
        <% end %>

      RESULT
    assert_equal(File.readlines(file_path), new_lines)
    assert_equal(File.read(file_path), expected_result)
  end

  it "inserts a new block then adds a line to it" do
    initial_data =
      <<~INITIAL

        <% outer_block do %>
          <% inner_block do %>
          <% end %>
        <% end %>

      INITIAL
    initialize_demo_file(file_path, initial_data)
    initial_lines = File.readlines(file_path)

    new_lines = Scaffolding::BlockManipulator.insert_block(["<% new_block do %>", "<% end %>"], after_block: "<% inner_block", lines: initial_lines)
    new_lines = Scaffolding::BlockManipulator.insert("  an inner line", within: "<% new_block", lines: new_lines)
    Scaffolding::FileManipulator.write(file_path, new_lines, strip: false)

    expected_result =
      <<~EXPECTED

        <% outer_block do %>
          <% inner_block do %>
          <% end %>
          <% new_block do %>
            an inner line
          <% end %>
        <% end %>

      EXPECTED
    assert_equal(File.readlines(file_path), new_lines)
    assert_equal(File.read(file_path), expected_result)
  end

  it "wraps a block with a new block" do
    initial_data =
      <<~DATA

        <% test_block do %>
        <% end %>

      DATA
    initialize_demo_file(file_path, initial_data)
    initial_lines = File.readlines(file_path)

    new_lines = Scaffolding::BlockManipulator.wrap_block(starting: "<% test_block", with: ["<% outer_block do %>", "<% end %>"], lines: initial_lines)
    Scaffolding::FileManipulator.write(file_path, new_lines, strip: false)

    expected_result =
      <<~RESULT

        <% outer_block do %>
          <% test_block do %>
          <% end %>
        <% end %>

      RESULT
    assert_equal(File.readlines(file_path), new_lines)
    assert_equal(File.read(file_path), expected_result)
  end

  it "wraps a nested block" do
    initial_data =
      <<~INITIAL

        <% test_block do %>
          <% inner_block do %>
          <% end %>
        <% end %>

      INITIAL
    initialize_demo_file(file_path, initial_data)
    initial_lines = File.readlines(file_path)

    new_lines = Scaffolding::BlockManipulator.wrap_block(starting: "<% inner_block do", with: ["<% wrapping_block do %>", "<% end %>"], lines: initial_lines)
    Scaffolding::FileManipulator.write(file_path, new_lines, strip: false)

    expected_result =
      <<~RESULT

        <% test_block do %>
          <% wrapping_block do %>
            <% inner_block do %>
            <% end %>
          <% end %>
        <% end %>

      RESULT
    assert_equal(File.readlines(file_path), new_lines)
    assert_equal(File.read(file_path), expected_result)
  end
end
