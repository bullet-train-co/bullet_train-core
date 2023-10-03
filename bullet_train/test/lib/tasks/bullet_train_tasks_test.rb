require "test_helper"
require "rake"
Rails.application.load_tasks

module BulletTrain::Tasks; end
class BulletTrain::Tasks::ResolveTaskTest < ActiveSupport::TestCase
  setup { @original_stdin = $stdin }
  teardown { $stdin = @original_stdin }

  test "resolves the path when passed BEGIN absolute path from annotated view" do
    inputs = [
      "<!-- BEGIN /Users/andrewculver/.rbenv/versions/3.1.2/lib/ruby/gems/3.1.0/gems/bullet_train-themes-light-1.0.10/app/views/themes/light/workflow/_box.html.erb -->",
      "n", # Would you like to eject the file into the local project? (y/n):
      "n" # Would you like to open `#{source_file[:absolute_path]}`? (y/n):
    ]
    stdin_mock = StringIO.new(inputs.join("\n"))
    stdin_mock.define_singleton_method(:ready?) { false }
    $stdin = stdin_mock

    assert_output /Absolute path:/ do
      Rake::Task["bullet_train:resolve"].invoke("--interactive")
      Rake::Task["bullet_train:resolve"].reenable
    end
  end

  test "resolves the path when passed END absolute path from annotated view" do
    inputs = [
      "<!-- END /Users/andrewculver/.rbenv/versions/3.1.2/lib/ruby/gems/3.1.0/gems/bullet_train-themes-light-1.0.10/app/views/themes/light/workflow/_box.html.erb -->",
      "n", # Would you like to eject the file into the local project? (y/n):
      "n" # Would you like to open `#{source_file[:absolute_path]}`? (y/n):
    ]
    stdin_mock = StringIO.new(inputs.join("\n"))
    stdin_mock.define_singleton_method(:ready?) { false }
    $stdin = stdin_mock

    assert_output /Absolute path:/ do
      Rake::Task["bullet_train:resolve"].invoke("--interactive")
      Rake::Task["bullet_train:resolve"].reenable
    end
  end
end
