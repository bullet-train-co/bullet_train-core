module BulletTrain
  module Themes
    module Light
      class CustomThemeFileReplacer
        include BulletTrain::Themes::Light::FileReplacer

        def initialize(original_theme, custom_theme)
          @original_theme = original_theme
          @custom_theme = custom_theme
          @repo_path = "./local/bullet_train-themes-#{@custom_theme}"
        end

        def replace_theme
          rename_cloned_files_and_directories_with_custom_theme_name
          replace_cloned_file_contents_with_custom_theme_contents
          transform_file_contents_with_custom_theme_name
          remove_custom_theme_from_main_app
          set_gem_to_v1
          update_gem_author_and_email
        end

        def rename_cloned_files_and_directories_with_custom_theme_name
          cloned_contents = Dir.glob("#{@repo_path}/**/*")
          cloned_directories = cloned_contents.select { |repo_content| File.directory?(repo_content) && repo_content.match?(/\/#{@original_theme}$/) }
          cloned_files = cloned_contents.select { |repo_content| File.file?(repo_content) && repo_content.split("/").last.match?(@original_theme) }

          (cloned_directories + cloned_files).each do |original_content|
            File.rename(original_content, original_content.gsub(@original_theme, @custom_theme))
          end
        end

        def replace_cloned_file_contents_with_custom_theme_contents
          repo_contents = Dir.glob("#{@repo_path}/**/*")
          cloned_files = repo_contents.select { |repo_content| File.file?(repo_content) && repo_content.match?(@custom_theme) }

          # Most files in the root of the starter repository should not replace what we cloned from the original theme gem.
          (Dir.glob("#{@repo_path}/*") << "#{@repo_path}/config/routes.rb").each { |file_to_skip| cloned_files.delete(file_to_skip) }

          cloned_files.each do |cloned_file|
            starter_repository_file = cloned_file.gsub(@repo_path, ".")

            # This file has a different directory structure than what is in the starter repository.
            starter_repository_file.gsub!("app/", "") if cloned_file.match?("lib/bullet_train/themes/#{@custom_theme}.rb")

            # Some files we have here like the gemspec don't exist in the starter repository, so we skip those.
            if File.exist?(starter_repository_file)
              begin
                BulletTrain::Themes::Light::FileReplacer.replace_content(old: cloned_file, new: starter_repository_file)
              rescue Errno::ENOENT => _
                puts "Couldn't replace contents for #{cloned_file}".red
              end
            end
          end

          # This is the only file that is copied from and pasted to the starter repository directly with
          # a new name when running the eject command, so we have to move it manually to the new gem.
          `mv ./tailwind.#{@custom_theme}.config.js #{@repo_path}/tailwind.#{@custom_theme}.config.js`
        end

        def transform_file_contents_with_custom_theme_name
          repo_contents = Dir.glob("#{@repo_path}/**/*")
          files_to_change = repo_contents.select { |repo_content| File.file?(repo_content) }
          original_theme_class_name = @original_theme.split(/[_|-]/).map(&:capitalize).join
          custom_theme_class_name = @custom_theme.split(/[_|-]/).map(&:capitalize).join
          new_lines = []

          files_to_change.each do |file|
            File.open(file, "r") do |f|
              new_lines = f.readlines
              next unless new_lines.join.match?(/#{@original_theme}|#{original_theme_class_name}/)

              new_lines = new_lines.map do |line|
                # Avoid replacing Tailwind styles like `font-light` and `font-extralight`.
                line.gsub!(@original_theme, @custom_theme) unless line.match?(/font-.*light/)
                line.gsub!(original_theme_class_name, custom_theme_class_name)
                line
              end
            end

            File.open(file, "w") do |f|
              f.puts new_lines.join
            end
          end
        end

        def remove_custom_theme_from_main_app
          files = [
            "./app/assets/stylesheets/#{@custom_theme}.tailwind.css",
            Dir.glob("./app/assets/stylesheets/#{@custom_theme}/**/*.css"),
            "./app/javascript/application.#{@custom_theme}.js",
            "./app/lib/bullet_train/themes/#{@custom_theme}.rb",
            Dir.glob("./app/views/themes/#{@custom_theme}/**/*.html.erb"),
          ].flatten
          files.each do |file|
            File.delete(file)
          end

          directories = [
            "./app/assets/stylesheets/#{@custom_theme}/",
            "./app/views/themes/#{@custom_theme}/",
            "./app/lib/"
          ].map { |directory| directory unless directory == "./app/lib/" && Dir.empty?(directory) }
          directories.compact.each { |directory| FileUtils.rm_rf(directory) }
        end

        def set_gem_to_v1
          new_lines = []
          File.open("#{@repo_path}/lib/bullet_train/themes/#{@custom_theme}/version.rb", "r") do |file|
            new_lines = file.readlines
            new_lines = new_lines.map { |line| line.match?("VERSION") ? "      VERSION = \"1.0\"\n" : line }
          end

          File.open("#{@repo_path}/lib/bullet_train/themes/#{@custom_theme}/version.rb", "w") do |file|
            file.puts new_lines.join
          end
        end

        def update_gem_author_and_email
          # If the developer hasn't set these yet, this should simply return empty strings.
          author = `git config --global user.name`.chomp
          email = `git config --global user.email`.chomp
          new_lines = []

          File.open("#{@repo_path}/bullet_train-themes-#{@custom_theme}.gemspec", "r") do |file|
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
          File.open("#{@repo_path}/bullet_train-themes-#{@custom_theme}.gemspec", "w") do |file|
            file.puts new_lines.join
          end
        end
      end
    end
  end
end
