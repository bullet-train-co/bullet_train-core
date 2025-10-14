require "test_helper"
require "rake"
Rails.application.load_tasks

module BulletTrain::Tasks; end

class BulletTrain::Tasks::ResolveTaskTest < ActiveSupport::TestCase
  setup do
    light_theme_gem = Gem::Specification.find_by_name("bullet_train-themes-light").gem_dir
    light_box_path = "#{light_theme_gem}/app/views/themes/light/workflow/_box.html.erb"
    @annotated_path = "<!-- BEGIN #{light_box_path} -->"
  end

  test "resolves the path when passed BEGIN absolute path from annotated view" do
    mock_stdin_with [
      @annotated_path,
      "n", # Would you like to eject the file into the local project? (y/n):
      "n" # Would you like to open `#{source_file[:absolute_path]}`? (y/n):
    ] do
      assert_output(/Absolute path:/) do
        Rake::Task["bullet_train:resolve"].invoke("--interactive")
        Rake::Task["bullet_train:resolve"].reenable
      end
    end
  end

  test "resolves the path when passed END absolute path from annotated view" do
    mock_stdin_with [
      @annotated_path,
      "n", # Would you like to eject the file into the local project? (y/n):
      "n" # Would you like to open `#{source_file[:absolute_path]}`? (y/n):
    ] do
      assert_output(/Absolute path:/) do
        Rake::Task["bullet_train:resolve"].invoke("--interactive")
        Rake::Task["bullet_train:resolve"].reenable
      end
    end
  end

  private

  def mock_stdin_with(inputs)
    old_stdin, $stdin = $stdin, StringIO.new(inputs.join("\n"))
    # StringIO doens't have `IO#ready?`, so we stub a method on the singleton.
    $stdin.define_singleton_method(:ready?) { false }
    yield
  ensure
    $stdin = old_stdin
  end
end
