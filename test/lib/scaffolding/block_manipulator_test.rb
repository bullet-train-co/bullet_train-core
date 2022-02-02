require "test_helper"
require "minitest/spec"

require_relative "../../../lib/scaffolding/block_manipulator"

describe Scaffolding::BlockManipulator do
  file_path = "./test/lib/scaffolding/examples/block_manipulator_data.html.erb"
  initial_data_state =
    <<~DATA

      <% test_block do %>
      <% end %>

    DATA

  it "initializes" do
    Scaffolding::BlockManipulator.new(file_path)
  end

  def initialize_demo_file file_path, data = nil
    File.write(file_path, (data || initial_data_state))
  end

  it "Inserts within a block and after the given location" do
    initial_data =
      <<~INITIAL

        <% test_block do %>
          <p>with some content</p>
        <% end %>

      INITIAL

    initialize_demo_file(file_path, initial_data)
    block_manipulator = Scaffolding::BlockManipulator.new(file_path)
    block_manipulator.insert("a new string", within: "<% test_block", after: "<p>")
    block_manipulator.write
    expected_result =
      <<~RESULT

        <% test_block do %>
          <p>with some content</p>
          a new string
        <% end %>

      RESULT
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
    block_manipulator = Scaffolding::BlockManipulator.new(file_path)
    block_manipulator.insert("  Some new content", within: "<% inner_block")
    block_manipulator.write
    expected_result =
      <<~EXPECTED

        <% outer_block do %>
          <% inner_block do %>
            Some new content
          <% end %>
        <% end %>

      EXPECTED
    assert_equal(File.read(file_path), expected_result)
  end

  it "Inserts content after the given block" do
    initial_data =
      <<~INITIAL

        <% outer_block do %>
          <% inner_block do %>
          <% end %>
        <% end %>

      INITIAL
    initialize_demo_file(file_path, initial_data)
    block_manipulator = Scaffolding::BlockManipulator.new(file_path)
    block_manipulator.insert("Post content", after_block: "<% inner_block")
    block_manipulator.write
    expected_result =
      <<~EXPECTED

        <% outer_block do %>
          <% inner_block do %>
          <% end %>
          Post content
        <% end %>

      EXPECTED
    assert_equal(File.read(file_path), expected_result)
  end

  it "appends a line after the block" do
    initialize_demo_file(file_path, initial_data_state)
    block_manipulator = Scaffolding::BlockManipulator.new(file_path)
    block_manipulator.insert("This is a new line", after_block: "<% test_block")
    block_manipulator.write
    expected_result =
      <<~RESULT

        <% test_block do %>
        <% end %>
        This is a new line

      RESULT
    assert_equal(File.read(file_path), expected_result)
  end

  it "Inserts within an if statement" do
    initial_data =
      <<~INITIAL

        <% if a_test %>
          <p>with some content</p>
        <% end %>

      INITIAL

    initialize_demo_file(file_path, initial_data)
    block_manipulator = Scaffolding::BlockManipulator.new(file_path)
    block_manipulator.insert("a new string", within: "<% if a_test", after: "<p>")
    block_manipulator.write
    expected_result =
      <<~RESULT

        <% if a_test %>
          <p>with some content</p>
          a new string
        <% end %>

      RESULT
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
    block_manipulator = Scaffolding::BlockManipulator.new(file_path)
    block_manipulator.insert_block(["<% new_block do %>", "<% end %>"], after_block: "<% inner_block")
    block_manipulator.insert("  an inner line", within: "<% new_block")
    block_manipulator.write
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
    assert_equal(File.read(file_path), expected_result)
  end

  it "Wraps a block with a new block" do
    initialize_demo_file(file_path, initial_data_state)
    block_manipulator = Scaffolding::BlockManipulator.new(file_path)
    block_manipulator.wrap_block(starting: "<% test_block", with: ["<% outer_block do %>", "<% end %>"])
    block_manipulator.write
    expected_result =
      <<~RESULT

        <% outer_block do %>
          <% test_block do %>
          <% end %>
        <% end %>

      RESULT
    assert_equal(File.read(file_path), expected_result)
  end

  it "Wraps a nested block" do
    initial_state =
      <<~INITIAL

        <% test_block do %>
          <% inner_block do %>
          <% end %>
        <% end %>

      INITIAL
    expected_result =
      <<~RESULT

        <% test_block do %>
          <% wrapping_block do %>
            <% inner_block do %>
            <% end %>
          <% end %>
        <% end %>

      RESULT
    initialize_demo_file(file_path, initial_state)
    block_manipulator = Scaffolding::BlockManipulator.new(file_path)
    block_manipulator.wrap_block(starting: "<% inner_block do", with: ["<% wrapping_block do %>", "<% end %>"])
    block_manipulator.write
    assert_equal(File.read(file_path), expected_result)
  end
end
