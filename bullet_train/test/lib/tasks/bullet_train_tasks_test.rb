require "test_helper"
require "minitest/spec"
require "rake"
Rails.application.load_tasks

describe "rake bullet_train:resolve --interactive" do
  before do
    @original_stdin = $stdin
    @original_stdout = $stdout
    $stdout = StringIO.new
  end

  after do
    $stdin = @original_stdin
    $stdout = @original_stdout
  end

  describe "when passed BEGIN absolute path from annotated view" do
    it "resolves the path" do
      inputs = [
        "<!-- BEGIN /Users/andrewculver/.rbenv/versions/3.1.2/lib/ruby/gems/3.1.0/gems/bullet_train-themes-light-1.0.10/app/views/themes/light/workflow/_box.html.erb -->",
        "n", # Would you like to eject the file into the local project? (y/n):
        "n" # Would you like to open `#{source_file[:absolute_path]}`? (y/n):
      ]
      stdin_mock = StringIO.new(inputs.join("\n"))
      stdin_mock.define_singleton_method(:ready?) { false }
      $stdin = stdin_mock

      Rake::Task["bullet_train:resolve"].invoke("--interactive")
      Rake::Task["bullet_train:resolve"].reenable

      output = $stdout.string
      assert output.include?("Absolute path:")
    end
  end

  describe "when passed END absolute path from annotated view" do
    it "resolves the path" do
      inputs = [
        "<!-- END /Users/andrewculver/.rbenv/versions/3.1.2/lib/ruby/gems/3.1.0/gems/bullet_train-themes-light-1.0.10/app/views/themes/light/workflow/_box.html.erb -->",
        "n", # Would you like to eject the file into the local project? (y/n):
        "n" # Would you like to open `#{source_file[:absolute_path]}`? (y/n):
      ]
      stdin_mock = StringIO.new(inputs.join("\n"))
      stdin_mock.define_singleton_method(:ready?) { false }
      $stdin = stdin_mock

      Rake::Task["bullet_train:resolve"].invoke("--interactive")
      Rake::Task["bullet_train:resolve"].reenable

      output = $stdout.string
      assert output.include?("Absolute path:")
    end
  end
end
