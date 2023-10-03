require "test_helper"
require "rake"
Rails.application.load_tasks

module BulletTrain::Tasks; end

class BulletTrain::Tasks::ResolveTaskTest < ActiveSupport::TestCase
  test "resolves the path when passed BEGIN absolute path from annotated view" do
    mock_stdin_with [
      "<!-- BEGIN /Users/andrewculver/.rbenv/versions/3.1.2/lib/ruby/gems/3.1.0/gems/bullet_train-themes-light-1.0.10/app/views/themes/light/workflow/_box.html.erb -->",
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
      "<!-- END /Users/andrewculver/.rbenv/versions/3.1.2/lib/ruby/gems/3.1.0/gems/bullet_train-themes-light-1.0.10/app/views/themes/light/workflow/_box.html.erb -->",
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
