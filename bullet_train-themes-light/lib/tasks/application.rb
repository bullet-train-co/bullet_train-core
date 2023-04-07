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

        {
          "bullet_train-themes" => "base",
          "bullet_train-themes-tailwind_css" => "tailwind_css",
          "bullet_train-themes-light" => "light"
        }.each do |gem, theme_name|
          gem_path = `bundle show --paths #{gem}`.chomp
          `find #{gem_path}/app/views/themes`.lines.map(&:chomp).each do |file_or_directory|
            target_file_or_directory = file_or_directory.gsub(gem_path, "").gsub("/#{theme_name}", "/#{ejected_theme_name}")
            target_file_or_directory = Rails.root.to_s + target_file_or_directory

            if File.directory?(file_or_directory)
              puts "Creating `#{target_file_or_directory}`."
              `mkdir #{target_file_or_directory}`
            else
              puts "Copying `#{target_file_or_directory}`."
              `cp #{file_or_directory} #{target_file_or_directory}`
            end
          end
        end

        %x(sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/#{theme_name}/#{ejected_theme_name}/g" #{Rails.root}/app/views/themes/#{ejected_theme_name}/layouts/_head.html.erb)

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
        ["require", "TODO", "mattr_accessor"].each do |thing_to_remove|
          `grep -v #{thing_to_remove} #{target_path} > #{target_path}.tmp`
          `mv #{target_path}.tmp #{target_path}`
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

        BulletTrain::Themes::Light::CustomThemeFileReplacer.new(original_theme_name, args[:theme_name]).replace_theme

        work_tree_flag = "--work-tree=local/bullet_train-themes-#{args[:theme_name]}"
        git_dir_flag = "--git-dir=local/bullet_train-themes-#{args[:theme_name]}/.git"
        path = "./local/bullet_train-themes-#{args[:theme_name]}"

        # Set up the proper remote.
        `git #{work_tree_flag} #{git_dir_flag} remote set-url origin #{ssh_path}`
        `git #{work_tree_flag} #{git_dir_flag} add .`
        `git #{work_tree_flag} #{git_dir_flag} commit -m "Add initial files"`

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
        puts "Look over the changes and commit them after trying out the gem and making sure everything works properly.".blue
        puts ""
        puts "Use `rake bullet_train:themes:light:install` to revert to the original theme,".blue
        puts "or run `rake bullet_train:themes:#{args[:theme_name]}:install` whenever you want to use your new theme.".blue
      end

      def self.install_theme(theme_name)
        # Grabs the current theme from
        # def current_theme
        #   :theme_name
        # end
        current_theme_regexp = /(^    :)(.*)/
        current_theme = nil

        new_lines = []
        [
          "./app/helpers/application_helper.rb",
          "./Procfile.dev",
          "./package.json"
        ].each do |file|
          File.open(file, "r") do |f|
            new_lines = f.readlines
            new_lines = new_lines.map do |line|
              # Make sure we get the current theme before trying to replace it in any of the files.
              # We grab it from the first file in the array above.
              current_theme = line.scan(current_theme_regexp).flatten.last if line.match?(current_theme_regexp)

              line.gsub!(/#{current_theme}/, theme_name) unless current_theme.nil?
              line
            end
          end

          File.open(file, "w") do |f|
            puts "Updating #{file}."
            f.puts new_lines.join
          end
        end

        puts "Finished installing `#{theme_name}`.".blue
      end

      def self.clean_theme(theme_name, args)
        theme_base_path = `bundle show --paths bullet_train-themes-#{theme_name}`.chomp
        `find app/views/themes/#{args[:theme]} | grep html.erb`.lines.map(&:chomp).each do |path|
          _, file = path.split("app/views/themes/#{args[:theme]}/")
          original_theme_path = "#{theme_base_path}/app/views/themes/#{theme_name}/#{file}"
          if File.read(path) == File.read(original_theme_path)
            puts "No changes in `#{path}` since being ejected. Removing."
            `rm #{path}`
          end
        end
      end

      def self.ask(string)
        puts string.blue
        $stdin.gets.strip
      end
    end
  end
end
