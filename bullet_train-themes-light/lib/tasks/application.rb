require "masamune"

module BulletTrain
  module Themes
    module Application
      def self.eject_theme(theme_name, ejected_theme_name)
        theme_parts = theme_name.humanize.split.map { |str| str.capitalize }
        constantized_theme = theme_parts.join
        humanized_theme = theme_parts.join(" ")

        theme_base_path = `bundle show --paths bullet_train-themes-#{theme_name}`.chomp
        puts "Ejecting from #{humanized_theme} theme in `#{theme_base_path}`."

        puts "Ejecting Tailwind configuration into `./tailwind.#{ejected_theme_name}.config.js`."
        `cp #{theme_base_path}/tailwind.#{theme_name}.config.js #{Rails.root}/tailwind.#{ejected_theme_name}.config.js`

        puts "Ejecting Tailwind mailer configuration into `./tailwind.mailer.#{ejected_theme_name}.config.js`."
        `cp #{theme_base_path}/tailwind.mailer.#{theme_name}.config.js #{Rails.root}/tailwind.mailer.#{ejected_theme_name}.config.js`
        %x(sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/#{theme_name}/#{ejected_theme_name}/g" #{Rails.root}/tailwind.mailer.#{ejected_theme_name}.config.js)

        puts "Ejecting stylesheets into `./app/assets/stylesheets/#{ejected_theme_name}`."
        `mkdir #{Rails.root}/app/assets/stylesheets`
        `cp -R #{theme_base_path}/app/assets/stylesheets/#{theme_name} #{Rails.root}/app/assets/stylesheets/#{ejected_theme_name}`
        `cp -R #{theme_base_path}/app/assets/stylesheets/#{theme_name}.tailwind.css #{Rails.root}/app/assets/stylesheets/#{ejected_theme_name}.tailwind.css`
        %x(sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/light/#{ejected_theme_name}/g" #{Rails.root}/app/assets/stylesheets/#{ejected_theme_name}.tailwind.css)

        puts "Ejecting JavaScript into `./app/javascript/application.#{ejected_theme_name}.js`."
        `cp #{theme_base_path}/app/javascript/application.#{theme_name}.js #{Rails.root}/app/javascript/application.#{ejected_theme_name}.js`

        `mkdir #{Rails.root}/app/views/themes`

        new_files = {}
        {
          "bullet_train-themes" => "base",
          "bullet_train-themes-tailwind_css" => "tailwind_css",
          "bullet_train-themes-light" => "light"
        }.each do |gem, theme_name|
          gem_path = `bundle show --paths #{gem}`.chomp
          showcase_partials = Dir.glob("#{gem_path}/app/views/showcase/**/*.html.erb")

          `find #{gem_path}/app/views/themes`.lines.map(&:chomp).each do |file_or_directory|
            target_file_or_directory = file_or_directory.gsub(gem_path, "").gsub("/#{theme_name}", "/#{ejected_theme_name}")
            target_file_or_directory = Rails.root.to_s + target_file_or_directory

            if File.directory?(file_or_directory)
              puts "Creating `#{target_file_or_directory}`."
              `mkdir #{target_file_or_directory}`
            else
              puts "Copying `#{target_file_or_directory}`."
              `cp #{file_or_directory} #{target_file_or_directory}`
              gem_with_version = gem_path.split("/").last
              new_files[target_file_or_directory] = file_or_directory.split(/(?=#{gem_with_version})/).last
            end

            # Look for showcase preview.
            file_name = target_file_or_directory.split("/").last
            showcase_preview = showcase_partials.find { _1.end_with?(file_name) }
            if showcase_preview
              puts "Ejecting showcase preview for #{target_file_or_directory}"
              partial_relative_path = showcase_preview.scan(/(?=app\/views\/showcase).*/).last
              directory = partial_relative_path.split("/")[0..-2].join("/")
              FileUtils.mkdir_p(directory)
              FileUtils.touch(partial_relative_path)
              `cp #{showcase_preview} #{partial_relative_path}`
              new_files[partial_relative_path] = "#{gem_path.scan(/#{gem}.*/).pop}/#{partial_relative_path}"
            end
          end
        end

        %x(sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/#{theme_name}/#{ejected_theme_name}/g" #{Rails.root}/app/views/themes/#{ejected_theme_name}/layouts/_head.html.erb)
        %x(sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/#{theme_name}/#{ejected_theme_name}/g" #{Rails.root}/app/views/themes/#{ejected_theme_name}/layouts/_mailer.html.erb)

        puts "Cutting local `Procfile.dev` over from `#{theme_name}` to `#{ejected_theme_name}`."
        %x(sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/#{theme_name}/#{ejected_theme_name}/g" #{Rails.root}/Procfile.dev)

        puts "Cutting local `package.json` over from `#{theme_name}` to `#{ejected_theme_name}`."
        %x(sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/#{theme_name}/#{ejected_theme_name}/g" #{Rails.root}/package.json)

        puts "Cutting `test/system/resolver_system_test.rb` over from `#{theme_name}` to `#{ejected_theme_name}`."
        %x(sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/light/#{ejected_theme_name}/g" #{Rails.root}/test/system/resolver_system_test.rb)

        # Stub out the class that represents this theme and establishes its inheritance structure.
        target_path = "#{Rails.root}/app/lib/bullet_train/themes/#{ejected_theme_name}.rb"
        puts "Stubbing out a class that represents this theme in `.#{target_path}`."
        `mkdir -p #{Rails.root}/app/lib/bullet_train/themes`
        `cp #{theme_base_path}/lib/bullet_train/themes/#{theme_name}.rb #{target_path}`
        %x(sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/module #{constantized_theme}/module #{ejected_theme_name.titlecase}/g" #{target_path})
        %x(sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/TailwindCss/#{constantized_theme}/g" #{target_path})
        %x(sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/#{theme_name}/#{ejected_theme_name}/g" #{target_path})

        theme_file = Pathname.new(target_path)
        msmn = Masamune::AbstractSyntaxTree.new(theme_file.readlines.join)
        data_to_skip =
          msmn.method_calls(token_value: "require") +
          msmn.method_calls(token_value: "mattr_accessor") +
          msmn.comments.select { |comment| comment.token_value.match?("TODO") }
        lines_to_skip = data_to_skip.map { |data| data.line_number - 1 }
        new_lines = theme_file.readlines.select.with_index do |line, idx|
          !lines_to_skip.include?(idx) || line.match?("mattr_accessor :colors")
        end
        theme_file.write new_lines.join

        # We add the comment to the ejected files here so the sed calls don't
        # overwrite package names like `bullet_train-themes-light`.
        new_files.each do |key, value|
          file = Pathname.new(key)
          lines = file.readlines

          new_lines = case key.split(".").last
          when "rb", "yml"
            lines.unshift("# Ejected from #{value}\n\n")
          when "erb"
            lines.unshift("<% # Ejected from #{value} %>\n\n")
          end
          file.write(new_lines.join)
        end

        `standardrb --fix #{target_path}`

        puts "Cutting local project over from `#{theme_name}` to `#{ejected_theme_name}` in `app/helpers/application_helper.rb`."
        %x(sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/:#{theme_name}/:#{ejected_theme_name}/g" #{Rails.root}/app/helpers/application_helper.rb)

        puts "You must restart `bin/dev` at this point, because of the changes to `Procfile.dev` and `package.json`."
      end

      def self.release_theme(original_theme_name, args)
        # We only want developers publishing gems off of `bullet_train-themes-light`, so if the task looks
        # something like `rake bullet_train:themes:foo:release[bar]`, we prevent them from moving any further here.
        if original_theme_name != "light"
          puts "You can only release new themes based off of Bullet Train's Light theme. Please eject a new theme from there, and publish your gem once you've finished making changes.".red
          exit 1
        elsif original_theme_name.nil?
          puts "Please run the command with the name of the theme you want to release.".red
          puts "For example: > rake bullet_train:themes:light:release[foo]"
        end

        puts "Preparing to release your custom theme: ".blue + args[:theme_name]
        puts ""
        puts "Before we make a new Ruby gem for your theme, you'll have to set up a GitHub repository first.".blue
        puts "Hit <Return> and we'll open a browser to GitHub where you can create a new repository.".blue
        puts "Make sure you name the repository ".blue + "bullet_train-themes-#{args[:theme_name]}"
        puts ""
        puts "When you're done, copy the SSH path from the new repository and return here.".blue
        ask "We'll ask you to paste it to us in the next step."
        `#{(Gem::Platform.local.os == "linux") ? "xdg-open" : "open"} https://github.com/new`

        ssh_path = ask "OK, what was the SSH path? (It should look like `git@github.com:your-account/your-new-repo.git`.)"
        puts ""
        puts "Great, you're all set.".blue
        puts "We'll take it from here, so sit back and enjoy the ride 🚄️".blue
        puts ""
        puts "Creating a Ruby gem for ".blue + "#{args[:theme_name]}..."

        Dir.mkdir("local") unless Dir.exist?("./local")
        if Dir.exist?("./local/bullet_train-themes-#{args[:theme_name]}")
          raise "You already have a repository named `bullet_train-themes-#{args[:theme_name]}` in `./local`.\n" \
            "Make sure you delete it first to create an entirely new gem."
        end

        # Pull `bullet_train-themes-light` only from `bullet_train-core` into the new theme directory.
        # https://www.git-scm.com/docs/git-sparse-checkout
        `mkdir ./local/bullet_train-themes-#{args[:theme_name]}`
        `cd ./local/bullet_train-themes-#{args[:theme_name]} && git init && git remote add bullet-train-core git@github.com:bullet-train-co/bullet_train-core.git`
        `cd ./local/bullet_train-themes-#{args[:theme_name]} && git config core.sparseCheckout true && echo "bullet_train-themes-light/**/*" >> .git/info/sparse-checkout`
        `cd ./local/bullet_train-themes-#{args[:theme_name]} && git pull bullet-train-core main && git remote rm bullet-train-core`
        `cd ./local/bullet_train-themes-#{args[:theme_name]} && mv bullet_train-themes-light/* . && mv bullet_train-themes-light/.* .`
        `cd ./local/bullet_train-themes-#{args[:theme_name]} && rmdir bullet_train-themes-light/`
        `cd ./local/bullet_train-themes-#{args[:theme_name]} && git config core.sparseCheckout false`

        BulletTrain::Themes::Light::CustomThemeFileReplacer.new(original_theme_name, args[:theme_name]).replace_theme

        work_tree_flag = "--work-tree=local/bullet_train-themes-#{args[:theme_name]}"
        git_dir_flag = "--git-dir=local/bullet_train-themes-#{args[:theme_name]}/.git"
        path = "./local/bullet_train-themes-#{args[:theme_name]}"

        # Set up the proper remote.
        `git #{work_tree_flag} #{git_dir_flag} remote add origin #{ssh_path}`
        `git #{work_tree_flag} #{git_dir_flag} add .`
        `git #{work_tree_flag} #{git_dir_flag} commit -m "Add initial files"`
        `git #{work_tree_flag} #{git_dir_flag} branch -m main`

        # Build the gem.
        `(cd #{path} && gem build bullet_train-themes-#{args[:theme_name]}.gemspec)`
        `git #{work_tree_flag} #{git_dir_flag} add .`
        `git #{work_tree_flag} #{git_dir_flag} commit -m "Build gem"`

        # Commit the deleted files on the main application.
        `git add .`
        `git commit -m "Remove #{args[:theme_name]} files from application"`

        # Push the gem's source code, but not the last commit in the main application.
        `git #{work_tree_flag} #{git_dir_flag} push -u origin main`

        puts ""
        puts ""
        puts "You're all set! Copy and paste the following commands to publish your gem:".blue
        puts "cd ./local/bullet_train-themes-#{args[:theme_name]}"
        puts "gem push bullet_train-themes-#{args[:theme_name]}-1.0.gem && cd ../../"
        puts ""
        puts "You may have to wait for some time until the gem can be downloaded via the Gemfile.".blue
        puts "After a few minutes, run the following command in your main application:".blue
        puts "bundle add bullet_train-themes-#{args[:theme_name]}"
        puts ""
        puts "Then you'll be ready to use your custom gem in your Bullet Train application.".blue
        puts ""
        puts "Please note that we have deleted the new theme from your main application.".blue
        puts "run `git log -1` for details."
        puts ""
        puts "Use `rake bullet_train:themes:light:install` to revert to the original theme,".blue
        puts "or run `rake bullet_train:themes:#{args[:theme_name]}:install` whenever you want to use your new theme.".blue
      end

      def self.install_theme(theme_name)
        helper = Pathname.new("./app/helpers/application_helper.rb")
        msmn = Masamune::AbstractSyntaxTree.new(helper.readlines.join)
        current_theme_def = msmn.method_definitions(token_value: "current_theme").pop
        current_theme = msmn.symbols.find { |node| node.line_number > current_theme_def.line_number }.token_value
        helper.write msmn.replace(type: :symbol, old_token_value: current_theme, new_token_value: theme_name)

        [Pathname.new("./Procfile.dev"), Pathname.new("./package.json")].each do |file|
          changed = file.read.gsub! current_theme, theme_name
          if changed
            file.write changed
          end
        end

        puts "Finished installing `#{theme_name}`.".blue
      end

      def self.clean_theme(theme_name, args)
        light_base_path = `bundle show --paths bullet_train-themes-light`.chomp
        tailwind_base_path = `bundle show --paths bullet_train-themes-tailwind_css`.chomp
        theme_base_path = `bundle show --paths bullet_train-themes`.chomp

        directory_content = `find . | grep 'app/.*#{args[:theme]}'`.lines.map(&:chomp)
        directory_content = directory_content.reject { |content| content.match?("app/assets/builds/") }
        files = directory_content.select { |file| file.match?(/(\.erb)|(\.rb)|(\.css)|(\.js)$/) }

        # Files that exist outside of "./app/" that we need to check.
        files += [
          "tailwind.#{args[:theme]}.config.js",
          "tailwind.mailer.#{args[:theme]}.config.js",
        ]

        # This file doesn't exist under "app/" in its original gem, so we handle it differently.
        # Also, don't remove this file from the starter repository in case
        # the developer has any ejected files that have been customized.
        files.delete("./app/lib/bullet_train/themes/#{args[:theme]}.rb")

        files.each do |file|
          original_theme_path = nil

          # Remove the current directory syntax for concatenation with the gem base path.
          file.gsub!("./", "")

          [light_base_path, tailwind_base_path, theme_base_path].each do |theme_path|
            # Views exist under "base" when the gem is "bullet_train-themes".
            theme_gem_name = theme_path.scan(/(.*themes-)(.*$)/).flatten.pop || "base"
            original_theme_path = file.gsub(args[:theme], theme_gem_name)

            if File.exist?("#{theme_path}/#{original_theme_path}")
              original_theme_path = "#{theme_path}/#{original_theme_path}"
              break
            end
          end

          ejected_file_content = File.read(file)

          # These are the only files where we replace the theme name inside of them when ejecting,
          # so we revert the contents and check if the file has been changed or not.
          transformed_files = [
            "app/views/themes/foo/layouts/_head.html.erb",
            "app/assets/stylesheets/foo.tailwind.css",
            "tailwind.mailer.#{args[:theme]}.config.js"
          ]
          ejected_file_content.gsub!(/#{args[:theme]}/i, theme_name) if transformed_files.include?(file)

          if ejected_file_content == File.read(original_theme_path)
            puts "No changes in `#{file}` since being ejected. Removing."
            `rm #{file}`
          end
        end

        # Delete all leftover directories with empty content.
        [
          "./app/assets/stylesheets/",
          "./app/views/themes/"
        ].each do |remaining_directory|
          puts "Cleaning out directory: #{remaining_directory}"
          remaining_directory_content = Dir.glob(remaining_directory + "**/*")
          remaining_directories = remaining_directory_content.select { |content| File.directory?(content) }
          remaining_directories.reverse_each { |dir| Dir.rmdir dir if Dir.empty?(dir) }
          FileUtils.rmdir(remaining_directory) if Dir.empty?(remaining_directory)
        end

        # These are files from the starter repository that need to be set back to the original theme.
        [
          "Procfile.dev",
          "app/helpers/application_helper.rb",
          "package.json",
          "test/system/resolver_system_test.rb"
        ].each do |file|
          puts "Reverting changes in #{file}."
          new_lines = File.open(file).readlines.join.gsub(/#{args[:theme]}/i, theme_name)
          File.write(file, new_lines)
        end
      end

      def self.ask(string)
        puts string.blue
        $stdin.gets.strip
      end
    end
  end
end
