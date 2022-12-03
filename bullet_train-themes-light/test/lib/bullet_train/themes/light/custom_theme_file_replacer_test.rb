require "test_helper"

class CustomThemeFileReplacerTest < ActiveSupport::TestCase
  def setup
    @file_replacer = BulletTrain::Themes::Light::CustomThemeFileReplacer.new("foo")
  end

  test "default_files_to_replace returns proper files" do
    default_files = [
      "./local/bullet_train-themes-foo/bullet_train-themes-light.gemspec",
      "./local/bullet_train-themes-foo/app/assets/config/bullet_train_themes_light_manifest.js",
      "./local/bullet_train-themes-foo/lib/tasks/bullet_train/themes/light_tasks.rake",
      "./local/bullet_train-themes-foo/test/bullet_train/themes/light_test.rb"
    ]
    assert_equal @file_replacer.default_files_to_replace("light"), default_files
  end

  test "files_whose_contents_need_to_be_replaced returns the proper files" do
    files = [
      "./local/bullet_train-themes-foo/app/assets/stylesheets/foo.tailwind.css",
      "./local/bullet_train-themes-foo/app/views/themes/foo/layouts/_account.html.erb",
      "./local/bullet_train-themes-foo/app/views/themes/foo/layouts/_devise.html.erb",
      "./local/bullet_train-themes-foo/bin/rails",
      "./local/bullet_train-themes-foo/lib/bullet_train/themes/foo/engine.rb",
      "./local/bullet_train-themes-foo/lib/bullet_train/themes/foo/version.rb",
      "./local/bullet_train-themes-foo/lib/bullet_train/themes/foo.rb",
      "./local/bullet_train-themes-foo/lib/tasks/bullet_train/themes/foo_tasks.rake",
      "./local/bullet_train-themes-foo/test/bullet_train/themes/foo_test.rb",
      "./local/bullet_train-themes-foo/test/dummy/app/views/layouts/mailer.html.erb",
      "./local/bullet_train-themes-foo/test/dummy/config/application.rb",
      "./local/bullet_train-themes-foo/bullet_train-themes-foo.gemspec",
      "./local/bullet_train-themes-foo/Gemfile",
      "./local/bullet_train-themes-foo/README.md"
    ]
    assert_equal @file_replacer.files_whose_contents_need_to_be_replaced("foo"), files
  end

  test "build_main_app_file_name returns file name that exists in the main app" do
    # This represents the file in the custom gem before it's renamed
    custom_gem_file = "./app/javascript/application.light.js"

    # The file in the main app HAS been renamed, so we build it here.
    main_app_file = @file_replacer.build_main_app_file_name("light", "foo", custom_gem_file)
    assert_equal main_app_file, "./app/javascript/application.foo.js"
  end

  test "adjust_directory_hierarchy returns the proper directory" do
    main_app_directory = "/app/lib/bullet_train/themes/foo"
    adjusted_directory = @file_replacer.adjust_directory_hierarchy(main_app_directory, "foo")
    assert_equal adjusted_directory, "/lib/bullet_train/themes/foo"
  end

  test "constantize_from_snake_case produces a constantized string" do
    assert_equal @file_replacer.constantize_from_snake_case("foo_bar"), "FooBar"
    assert_equal @file_replacer.constantize_from_snake_case("foo-bar"), "FooBar"
  end
end
