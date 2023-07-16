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
        "<!-- BEGIN /ruby-3.2.2/gems/bullet_train-themes-light-1.2.26/app/views/themes/light/_notices.html.erb -->",
        "n", # Would you like to eject the file into the local project? (y/n):
        "n" # Would you like to open `#{source_file[:absolute_path]}`? (y/n):
      ]
      $stdin = StringIO.new(inputs.join("\n"))

      Rake::Task["bullet_train:resolve"].invoke("--interactive")
      Rake::Task["bullet_train:resolve"].reenable

      output = $stdout.string
      assert output.include?("Absolute path:")
    end
  end

  describe "when passed END absolute path from annotated view" do
    it "resolves the path" do
      inputs = [
        "<!-- END /ruby-3.2.2/gems/bullet_train-themes-light-1.2.26/app/views/themes/light/_notices.html.erb -->",
        "n", # Would you like to eject the file into the local project? (y/n):
        "n" # Would you like to open `#{source_file[:absolute_path]}`? (y/n):
      ]
      $stdin = StringIO.new(inputs.join("\n"))

      Rake::Task["bullet_train:resolve"].invoke("--interactive")
      Rake::Task["bullet_train:resolve"].reenable

      output = $stdout.string
      assert output.include?("Absolute path:")
    end
  end
end
