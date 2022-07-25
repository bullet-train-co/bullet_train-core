namespace :bullet_train do
  namespace :themes do
    namespace :light do
      desc "Fork the \"Light\" theme into your local repository."
      task :eject, [:destination] => :environment do |task, args|
        theme_base_path = `bundle show --paths bullet_train-themes-light`.chomp
        puts "Ejecting from Light theme in `#{theme_base_path}`."

        puts "Ejecting Tailwind configuration into `./tailwind.#{args[:destination]}.config.js`."
        `cp #{theme_base_path}/tailwind.light.config.js #{Rails.root}/tailwind.#{args[:destination]}.config.js`

        puts "Ejecting Tailwind mailer configuration into `./tailwind.mailer.#{args[:destination]}.config.js`."
        `cp #{theme_base_path}/tailwind.mailer.light.config.js #{Rails.root}/tailwind.mailer.#{args[:destination]}.config.js`
        `sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/light/#{args[:destination]}/g" #{Rails.root}/tailwind.mailer.#{args[:destination]}.config.js`

        puts "Ejecting stylesheets into `./app/assets/stylesheets/#{args[:destination]}`."
        `mkdir #{Rails.root}/app/assets/stylesheets`
        `cp -R #{theme_base_path}/app/assets/stylesheets/light #{Rails.root}/app/assets/stylesheets/#{args[:destination]}`
        `cp -R #{theme_base_path}/app/assets/stylesheets/light.tailwind.css #{Rails.root}/app/assets/stylesheets/#{args[:destination]}.tailwind.css`
        `sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/light/#{args[:destination]}/g" #{Rails.root}/app/assets/stylesheets/#{args[:destination]}.tailwind.css`

        puts "Ejecting JavaScript into `./app/javascript/application.#{args[:destination]}.js`."
        `cp #{theme_base_path}/app/javascript/application.light.js #{Rails.root}/app/javascript/application.#{args[:destination]}.js`

        puts "Ejecting all theme partials into `./app/views/themes/#{args[:destination]}`."
        `mkdir #{Rails.root}/app/views/themes`
        `cp -R #{theme_base_path}/app/views/themes/light #{Rails.root}/app/views/themes/#{args[:destination]}`
        `sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/light/#{args[:destination]}/g" #{Rails.root}/app/views/themes/#{args[:destination]}/layouts/_head.html.erb`

        puts "Cutting local `Procfile.dev` over from `light` to `#{args[:destination]}`."
        `sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/light/#{args[:destination]}/g" #{Rails.root}/Procfile.dev`

        puts "Cutting local `package.json` over from `light` to `#{args[:destination]}`."
        `sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/light/#{args[:destination]}/g" #{Rails.root}/package.json`

        # Stub out the class that represents this theme and establishes its inheritance structure.
        target_path = "#{Rails.root}/app/lib/bullet_train/themes/#{args[:destination]}.rb"
        puts "Stubbing out a class that represents this theme in `.#{target_path}`."
        `mkdir -p #{Rails.root}/app/lib/bullet_train/themes`
        `cp #{theme_base_path}/lib/bullet_train/themes/light.rb #{target_path}`
        `sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/module Light/module #{args[:destination].titlecase}/g" #{target_path}`
        `sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/TailwindCss/Light/g" #{target_path}`
        `sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/light/#{args[:destination]}/g" #{target_path}`
        ["require", "TODO", "mattr_accessor"].each do |thing_to_remove|
          `grep -v #{thing_to_remove} #{target_path} > #{target_path}.tmp`
          `mv #{target_path}.tmp #{target_path}`
        end
        `standardrb --fix #{target_path}`

        puts "Cutting local project over from `light` to `#{args[:destination]}` in `app/helpers/application_helper.rb`."
        `sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/:light/:#{args[:destination]}/g" #{Rails.root}/app/helpers/application_helper.rb`

        puts "You must restart `bin/dev` at this point, because of the changes to `Procfile.dev` and `package.json`."
      end

      desc "Publish your custom theme theme as a Ruby gem."
      task :release, [:theme_name] => :environment do |task, args|
        puts "Preparing to release your custom theme: ".blue + args[:theme_name]
        puts ""
        puts "Before we make a new Ruby gem for your theme, you'll have to set up a GitHub repository first.".blue
        puts "Hit <Return> and we'll open a browser to GitHub where you can create a new repository.".blue
        puts "Make sure you name the repository ".blue + "bullet_train-themes-#{args[:theme_name]}"
        puts ""
        puts "When you're done, copy the SSH path from the new repository and return here.".blue
        ask "We'll ask you to paste it to us in the next step."
        `#{Gem::Platform.local.os == "linux" ? "xdg-open" : "open"} https://github.com/new`

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
        `git clone git@github.com:bullet-train-co/bullet_train-themes-light.git ./local/bullet_train-themes-#{args[:theme_name]}`

        custom_file_replacer = BulletTrain::Themes::Light::CustomThemeFileReplacer.new(args[:theme_name])
        custom_file_replacer.replace_theme("light", args[:theme_name])

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
      end

      desc "Install this theme to your main application."
      task :install do |rake_task|
        # Grab the theme name from the rake task, bullet_train:theme:light:install
        theme_name = rake_task.name.split(":")[2]

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
            f.puts new_lines.join
          end
        end
      end

      def ask(string)
        puts string.blue
        $stdin.gets.strip
      end
    end
  end
end
