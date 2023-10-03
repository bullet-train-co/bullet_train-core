require "test_helper"
require "scaffolding/block_manipulator"

class Scaffolding::BlockManipulatorTest < ActiveSupport::TestCase
  file_path = "./test/lib/scaffolding/examples/block_manipulator_data.html.erb"
  initial_file_contents =
    <<~INITIAL

      <% test_block do %>
        <p>with some content</p>
      <% end %>
    INITIAL

  teardown do
    File.write(file_path, initial_file_contents)
  end

  private def initialize_demo_file(file_path, data = nil)
    File.write(file_path, data)
  end

  test "inserts within a block and after the given location" do
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
    assert_equal File.readlines(file_path), new_lines
    assert_equal File.read(file_path), expected_result
  end

  test "inserts multiple lines within a block using the proper indentation" do
    initial_data =
      <<~INITIAL
        <% test_block do %>
        <% end %>
      INITIAL
    initialize_demo_file(file_path, initial_data)
    initial_lines = File.readlines(file_path)

    content = ["first", "second", "third"]
    new_lines = Scaffolding::BlockManipulator.insert(content, within: "<% test_block do %>", lines: initial_lines)
    Scaffolding::FileManipulator.write(file_path, new_lines, strip: false)

    expected_result =
      <<~RESULT
        <% test_block do %>
          first
          second
          third
        <% end %>
      RESULT
    assert_equal File.readlines(file_path), new_lines
    assert_equal File.read(file_path), expected_result
  end

  test "inserts multiple lines within a block when using a heredoc" do
    initial_data =
      <<~INITIAL
        <% test_block do %>
        <% end %>
      INITIAL
    initialize_demo_file(file_path, initial_data)
    initial_lines = File.readlines(file_path)

    content = <<~CONTENT
      first
      second
      third
    CONTENT

    new_lines = Scaffolding::BlockManipulator.insert(content, within: "<% test_block do %>", lines: initial_lines)
    Scaffolding::FileManipulator.write(file_path, new_lines, strip: false)

    expected_result =
      <<~RESULT
        <% test_block do %>
          first
          second
          third
        <% end %>
      RESULT
    assert_equal File.readlines(file_path), new_lines
    assert_equal File.read(file_path), expected_result
  end

  test "inserts into an empty block" do
    initial_data =
      <<~INITIAL

        <% outer_block do %>
          <% inner_block do %>
          <% end %>
        <% end %>

      INITIAL
    initialize_demo_file(file_path, initial_data)
    initial_lines = File.readlines(file_path)

    new_lines = Scaffolding::BlockManipulator.insert("Some new content", within: "<% inner_block", lines: initial_lines)
    Scaffolding::FileManipulator.write(file_path, new_lines, strip: false)

    expected_result =
      <<~EXPECTED

        <% outer_block do %>
          <% inner_block do %>
            Some new content
          <% end %>
        <% end %>

      EXPECTED
    assert_equal File.readlines(file_path), new_lines
    assert_equal File.read(file_path), expected_result
  end

  test "inserts content after the given block" do
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
    assert_equal File.readlines(file_path), new_lines
    assert_equal File.read(file_path), expected_result
  end

  test "appends a line after the block" do
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
    assert_equal File.readlines(file_path), new_lines
    assert_equal File.read(file_path), expected_result
  end

  test "inserts within an if statement" do
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
    assert_equal File.readlines(file_path), new_lines
    assert_equal File.read(file_path), expected_result
  end

  test "inserts a new block then adds a line to it" do
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
    new_lines = Scaffolding::BlockManipulator.insert("an inner line", within: "<% new_block", lines: new_lines)
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
    assert_equal File.readlines(file_path), new_lines
    assert_equal File.read(file_path), expected_result
  end

  test "wraps a block with a new block" do
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
    assert_equal File.readlines(file_path), new_lines
    assert_equal File.read(file_path), expected_result
  end

  test "wraps a nested block" do
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
    assert_equal File.readlines(file_path), new_lines
    assert_equal File.read(file_path), expected_result
  end

  test "unwraps a nested block" do
    initial_data =
      <<~INITIAL

        <% block_to_remove do %>
          <% block_to_unwrap do %>
          <% end %>
        <% end %>

      INITIAL

    initialize_demo_file(file_path, initial_data)
    initial_lines = File.readlines(file_path)

    new_lines = Scaffolding::BlockManipulator.unwrap_block(lines: initial_lines, block_start: "block_to_unwrap")
    Scaffolding::FileManipulator.write(file_path, new_lines, strip: false)

    expected_result =
      <<~RESULT

        <% block_to_unwrap do %>
        <% end %>

      RESULT

    assert_equal File.readlines(file_path), new_lines
    assert_equal File.read(file_path), expected_result
  end

  # Using an Array instead of a Heredoc to get the test the proper spacing.
  test "shifts a block's contents to the left" do
    initial_data =
      [
        "block_with_contents do\n",
        "    puts 'contents'\n",
        "end\n"
      ]

    initialize_demo_file(file_path, initial_data.join)
    initial_lines = File.readlines(file_path)

    new_lines = Scaffolding::BlockManipulator.shift_block(
      lines: initial_lines,
      block_start: initial_data.first,
      shift_contents_only: true
    )
    Scaffolding::FileManipulator.write(file_path, new_lines, strip: false)

    expected_result =
      [
        "block_with_contents do\n",
        "  puts 'contents'\n",
        "end\n"
      ]

    assert_equal File.readlines(file_path), new_lines
    assert_equal File.read(file_path), expected_result.join
  end

  # Using an Array instead of a Heredoc to get the test the proper spacing.
  test "shifts a block's contents to the right" do
    initial_data =
      [
        "block_with_contents do\n",
        "puts 'contents'\n",
        "end\n"
      ]

    initialize_demo_file(file_path, initial_data.join)
    initial_lines = File.readlines(file_path)

    new_lines = Scaffolding::BlockManipulator.shift_block(
      lines: initial_lines,
      direction: :right,
      block_start: initial_data.first,
      shift_contents_only: true
    )
    Scaffolding::FileManipulator.write(file_path, new_lines, strip: false)

    expected_result =
      [
        "block_with_contents do\n",
        "  puts 'contents'\n",
        "end\n"
      ]

    assert_equal File.readlines(file_path), new_lines
    assert_equal File.read(file_path), expected_result.join
  end
end
