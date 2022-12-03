module BulletTrain
  module Themes
    module Light
      class CustomThemeFileReplacer
        mattr_accessor :repo_path

        include BulletTrain::Themes::Light::FileReplacer

        def initialize(custom_theme)
          @repo_path = "./local/bullet_train-themes-#{custom_theme}"
        end

        def replace_theme(original_theme, custom_theme)
          # Rename the directories
          [
            "/app/assets/stylesheets/bullet_train/themes/#{original_theme}/",
            "/app/assets/stylesheets/#{original_theme}/",
            "/app/views/themes/#{original_theme}/",
            "/lib/bullet_train/themes/#{original_theme}/"
          ].map { |file| @repo_path + file }.each do |original_directory|
            custom_directory = original_directory.gsub(/(.*)(#{original_theme})(\/$)/, '\1' + custom_theme + '\3')
            FileUtils.mv(original_directory, custom_directory)
          end

          # Only compare ejected files.
          files_to_replace =
            ejected_files_to_replace(original_theme, custom_theme).map { |file| {file_name: file, must_compare: true} } +
            default_files_to_replace(original_theme).map { |file| {file_name: file, must_compare: false} }

          # Replace the file contents and rename the files.
          files_to_replace.each do |custom_gem_file|
            # All of the files we want to compare against the fresh gem are in the main app.
            main_app_file = build_main_app_file_name(original_theme, custom_theme, custom_gem_file[:file_name].gsub(@repo_path, "."))
            custom_gem_file[:file_name] = adjust_directory_hierarchy(custom_gem_file[:file_name], original_theme)

            # The content in the main app should replace the cloned gem files.
            begin
              if custom_gem_file[:must_compare] && !BulletTrain::Themes::Light::FileReplacer.files_have_same_content?(custom_gem_file[:file_name], main_app_file)
                BulletTrain::Themes::Light::FileReplacer.replace_content(old: custom_gem_file[:file_name], new: main_app_file)
              end
            rescue Errno::ENOENT => _
              puts "Skipping `#{main_app_file}` because it isn't present."
            end

            # Only rename file names that still have the original theme in them, i.e. - ./tailwind.config.light.js
            if File.basename(custom_gem_file[:file_name]).match?(original_theme)
              main_app_file = adjust_directory_hierarchy(main_app_file, custom_theme)
              new_file_name = main_app_file.gsub(/^\./, @repo_path).gsub(original_theme, custom_theme)
              File.rename(custom_gem_file[:file_name], new_file_name)
            end
          end

          # Change the content of specific files that contain the orignal theme's string.
          # i.e. - `module Light` and `tailwind.light.config`.
          constantized_original = constantize_from_snake_case(original_theme)
          constantized_custom = constantize_from_snake_case(custom_theme)
          files_whose_contents_need_to_be_replaced(custom_theme).each do |file|
            new_lines = []
            File.open(file, "r") do |f|
              new_lines = f.readlines
              new_lines = new_lines.map do |line|
                # We want the original theme it's being edited from when creating a new theme.
                # We also remove mattr_accessor in the eject task, so we need to add it back here.
                if f.path == "#{@repo_path}/lib/bullet_train/themes/#{custom_theme}.rb" && line.match?("class Theme < BulletTrain::Themes::")
                  line = "      mattr_accessor :color, default: :blue\n      class Theme < BulletTrain::Themes::#{constantize_from_snake_case(original_theme)}::Theme\n"
                else
                  # `_account.html.erb` and `_devise.html.erb` have tailwind classes that contain `light`.
                  # We shouldn't be replacing the classes with the custom theme string, so we skip it here.
                  # TODO: We should change this Regexp to check if the original theme is prefixed with `-`.
                  # If it is, we ignore the string if it's not prefixed with `bullet_train-themes-`,
                  line.gsub!(original_theme, custom_theme) unless line.match?("bg-light-gradient")
                  line.gsub!(constantized_original, constantized_custom)
                end
                line
              end
            end

            File.open(file, "w") do |f|
              f.puts new_lines.join
            end
          end

          # The contents in this specific main app file don't have the require statements which the gem
          # originally has, so we add those back after moving the main app file contents to the gem.
          new_lines = nil
          File.open("#{@repo_path}/lib/bullet_train/themes/#{custom_theme}.rb", "r") do |file|
            new_lines = file.readlines
            require_lines =
              <<~RUBY
                require "bullet_train/themes/#{custom_theme}/version"
                require "bullet_train/themes/#{custom_theme}/engine"
                require "bullet_train/themes/#{original_theme}"

              RUBY
            new_lines.unshift(require_lines)
          end
          File.open("#{@repo_path}/lib/bullet_train/themes/#{custom_theme}.rb", "w") do |file|
            file.puts new_lines.flatten.join
          end

          # Since we're generating a new gem, it should be version 1.0
          File.open("#{@repo_path}/lib/bullet_train/themes/#{custom_theme}/version.rb", "r") do |file|
            new_lines = file.readlines
            new_lines = new_lines.map { |line| line.match?("VERSION") ? "      VERSION = \"1.0\"\n" : line }
          end
          File.open("#{@repo_path}/lib/bullet_train/themes/#{custom_theme}/version.rb", "w") do |file|
            file.puts new_lines.join
          end

          # Remove files and directories from the main application.
          files_to_remove_from_main_app(custom_theme).each { |file| File.delete(file) }
          directories_to_remove_from_main_app(custom_theme).each do |directory|
            FileUtils.rm_rf(directory) unless directory.nil?
          end

          # Update the author and email.
          # If the developer hasn't set these yet, this should simply return empty strings.
          author = `git config --global user.name`.chomp
          email = `git config --global user.email`.chomp
          File.open("#{@repo_path}/bullet_train-themes-#{custom_theme}.gemspec", "r") do |file|
            new_lines = file.readlines
            new_lines = new_lines.map do |line|
              if line.match?("spec.authors")
                "  spec.authors = [\"#{author}\"]\n"
              elsif line.match?("spec.email")
                "  spec.email = [\"#{email}\"]\n"
              else
                line
              end
            end
          end
          File.open("#{@repo_path}/bullet_train-themes-#{custom_theme}.gemspec", "w") do |file|
            file.puts new_lines.join
          end
        end

        # By the time we call this method we have already updated the new gem's directories with
        # the custom theme name, but the FILE names are still the same from when they were cloned,
        # so we use `original_theme` for specific file names below.
        def ejected_files_to_replace(original_theme, custom_theme)
          [
            Dir.glob("#{@repo_path}/app/assets/stylesheets/#{custom_theme}/**/*.css"),
            Dir.glob("#{@repo_path}/app/assets/stylesheets/#{custom_theme}/**/*.scss"),
            Dir.glob("#{@repo_path}/app/views/themes/#{custom_theme}/**/*.html.erb"),
            "/app/javascript/application.#{original_theme}.js",
            "/tailwind.#{original_theme}.config.js",
            "/app/lib/bullet_train/themes/#{original_theme}.rb",
            # The Glob up top doesn't grab the #{original_theme}.tailwind.css file, so we set that here.
            "/app/assets/stylesheets/#{original_theme}.tailwind.css",
            "/tailwind.mailer.#{original_theme}.config.js"
          ].flatten.map { |file| file.match?(/^#{@repo_path}/) ? file : @repo_path + file }
        end

        # These files represent ones such as "./lib/bullet_train/themes/light.rb" which
        # aren't ejected to the developer's main app, but still need to be changed.
        def default_files_to_replace(original_theme)
          # TODO: Add this file and the FileReplacer module once they're added to the main branch.
          [
            "/bullet_train-themes-#{original_theme}.gemspec",
            "/app/assets/config/bullet_train_themes_#{original_theme}_manifest.js",
            "/lib/tasks/bullet_train/themes/#{original_theme}_tasks.rake",
            "/test/bullet_train/themes/#{original_theme}_test.rb"
          ].map { |file| @repo_path + file }
        end

        def files_to_remove_from_main_app(custom_theme)
          [
            Dir.glob("./app/assets/stylesheets/#{custom_theme}/**/*.css"),
            Dir.glob("./app/assets/stylesheets/#{custom_theme}/**/*.scss"),
            "./app/assets/stylesheets/#{custom_theme}.tailwind.css",
            "./app/javascript/application.#{custom_theme}.js",
            "./app/lib/bullet_train/themes/#{custom_theme}.rb",
            Dir.glob("./app/views/themes/#{custom_theme}/**/*.html.erb"),
            "./tailwind.mailer.#{custom_theme}.config.js",
            "./tailwind.#{custom_theme}.config.js",
          ].flatten
        end

        def files_whose_contents_need_to_be_replaced(custom_theme)
          [
            "/app/assets/stylesheets/#{custom_theme}.tailwind.css",
            "/app/views/themes/#{custom_theme}/layouts/_account.html.erb",
            "/app/views/themes/#{custom_theme}/layouts/_devise.html.erb",
            "/bin/rails",
            "/lib/bullet_train/themes/#{custom_theme}/engine.rb",
            "/lib/bullet_train/themes/#{custom_theme}/version.rb",
            "/lib/bullet_train/themes/#{custom_theme}.rb",
            "/lib/tasks/bullet_train/themes/#{custom_theme}_tasks.rake",
            "/test/bullet_train/themes/#{custom_theme}_test.rb",
            "/test/dummy/app/views/layouts/mailer.html.erb",
            "/test/dummy/config/application.rb",
            "/bullet_train-themes-#{custom_theme}.gemspec",
            "/Gemfile",
            "/README.md"
          ].map { |file| @repo_path + file }
        end

        def directories_to_remove_from_main_app(custom_theme)
          [
            "./app/assets/stylesheets/#{custom_theme}/",
            "./app/views/themes/#{custom_theme}/",
            "./app/lib/"
          ].map { |directory| directory unless directory == "./app/lib/" && Dir.empty?(directory) }
        end

        # Since we're cloning a fresh gem, file names that contain the original
        # theme stay the same, i.e. - tailwind.light.config.js. However, the names have
        # already been changed in the main app when the original theme was ejected.
        # Here, we build the correct string that is in the main app to compare the
        # files' contents. Then later on we actually rename the new gem's file names.
        def build_main_app_file_name(original_theme, custom_theme, custom_gem_file)
          main_app_file = custom_gem_file
          custom_gem_file_hierarchy = custom_gem_file.split("/")
          if custom_gem_file_hierarchy.last.match?(original_theme)
            custom_gem_file_hierarchy.last.gsub!(original_theme, custom_theme)
            main_app_file = custom_gem_file_hierarchy.join("/")
          end
          main_app_file
        end

        # This addresses one specific file where the hierarchy is
        # different after the file is ejected into the main application.
        def adjust_directory_hierarchy(file_name, theme_name)
          file_name.match?("lib/bullet_train/themes/#{theme_name}") ? file_name.gsub(/\/app/, "") : file_name
        end

        # i.e. - foo_bar or foo-bar to FooBar
        def constantize_from_snake_case(str)
          str.split(/[_|-]/).map(&:capitalize).join
        end
      end
    end
  end
end
