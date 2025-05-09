require "io/wait"
require "colorize"

namespace :bullet_train do
  desc "Figure out where something is coming from."
  task :resolve, [:all_options] => :environment do |t, arguments|
    ARGV.pop while ARGV.any?

    arguments[:all_options]&.split&.each do |argument|
      ARGV.push(argument)
    end

    if ARGV.include?("--interactive")
      puts "\nOK, paste what you've got for us and hit <Return>!\n".blue

      input = $stdin.gets.strip
      # we only resolve the first line of user input and ignore the rest
      $stdin.getc while $stdin.ready?

      # Extract absolute paths from annotated views.
      if input =~ /<!-- BEGIN (.*) -->/
        input = $1
      elsif input =~ /<!-- END (.*) -->/
        input = $1
      end

      # Append the main application's path if the file is a local file.
      # i.e. - app/views/layouts/_head.html.erb
      if input.match?(/^app/)
        input = "#{Rails.root}/#{input}"
      end

      ARGV.unshift input.strip
    end

    if ARGV.first.present?
      BulletTrain::Resolver.new(ARGV.first).run(eject: ARGV.include?("--eject"), open: ARGV.include?("--open"), force: ARGV.include?("--force"), interactive: ARGV.include?("--interactive"))
    else
      warn <<~MSG
        🚅 Usage: #{"`bin/resolve [path, partial, or URL] (--eject) (--open)`".blue}

        OR

        #{"`bin/resolve --interactive`".blue}
        When you use the interactive flag, we will prompt you to pass an annotated partial like so and either eject or open the file.
        These annotated paths can be found in your browser when inspecting elements:
        <!-- BEGIN /your/path/.rbenv/versions/3.1.2/lib/ruby/gems/3.1.0/gems/bullet_train-themes-light-1.0.51/app/views/themes/light/_notices.html.erb -->
      MSG
    end
  end

  desc "Eject files from the Bullet Train's core logic to your application."
  task :eject, [:type] => :environment do |task, args|
    if args[:type] == "locales"
      gem_names = I18n.t("framework_packages").map { |key, value| key.to_s }
      gem_names.each do |gem|
        puts "Searching for locales in #{gem}...".blue
        gem_path = `bundle show #{gem}`.chomp
        gem_with_version = gem_path.split("/").last
        locales = Dir.glob("#{gem_path}/**/config/locales/**/*.yml").reject { |path| path.match?("dummy") }
        next if locales.empty?

        puts "Found locales. Ejecting to your application...".green
        locales.each do |locale|
          relative_path = locale.split(/(?=#{gem_with_version}\/config\/locales)/).last
          path_in_locale = locale.split("/config/locales").pop

          base_path = relative_path.split("/")
          base_path.pop
          base_path = base_path.join("/")
          starter_repo_locale_path = base_path.gsub(gem_with_version, ".")

          FileUtils.mkdir_p(starter_repo_locale_path) unless Dir.exist?(starter_repo_locale_path)

          unless File.exist?("config/locales#{path_in_locale}")
            puts "Ejecting #{path_in_locale}..."
            File.new("config/locales#{path_in_locale}", "w")
            `cp #{locale} config/locales#{path_in_locale}`
            file = Pathname.new("config/locales#{path_in_locale}")
            lines = file.readlines
            lines.unshift("# Ejected from #{relative_path}\n\n")
            file.write(lines.join)
          end
        end
      end
    end
  end

  task :hack, [:all_options] => :environment do |t, arguments|
    def stream(command, prefix = "  ")
      puts ""

      begin
        trap("SIGINT") { throw :ctrl_c }

        IO.popen(command) do |io|
          while (line = io.gets)
            puts "#{prefix}#{line}"
          end
        end
      rescue UncaughtThrowError
        puts "Received a <Control + C>. Exiting the child process.".blue
      end

      puts ""
    end

    framework_packages = I18n.t("framework_packages")

    # Process any flags that were passed.
    if arguments[:all_options].present?
      flags_with_values = []

      arguments[:all_options].split(/\s+/).each do |option|
        if option.match?(/^--/)
          flags_with_values << {flag: option, values: []}
        else
          flags_with_values.last[:values] << option
        end
      end

      if flags_with_values.any?
        flags_with_values.each do |process|
          case process[:flag]
          when "--help"
            puts ""
            puts "bin/hack: " + "Clone bullet_train-core and link up gems (will only link up gems if already cloned).".blue
            puts "bin/hack --link: " + "Link all of your Bullet Train gems to `local/bullet_train-core`.".blue
            puts "bin/hack --link github: " + "Link all of your Bullet Train gems to the public repositories on GitHub".blue
            puts "bin/hack --link (version-number): " + "Link all of your Bullet Train gems to the version number passed.".blue
            puts "bin/hack --link (custom path to package): " + "Pass a custom path to where your bullet_train-core gems are.".blue
            puts "bin/hack --reset: " + "Resets all of your gems to their original definition.".blue
            puts "bin/hack --watch-js: " + "Watches for any changes in JavaScript files gems that have an npm package.".blue
            puts "bin/hack --clean-js: " + "Resets all of your npm packages from `local/bullet_train-core` to their original definition.".blue
            exit
          when "--link", "--reset"
            link_flag_value = process[:values].pop
            set_core_gems(process[:flag], link_flag_value, framework_packages)

            # Bundler will throw an error if we try to `bundle install` right after adding the GitHub link to the Gemfile.
            if link_flag_value == "github"
              puts ""
              puts "Now you can run `bundle install` to check out the public repositories on GitHub."
            else
              stream "bundle install"
            end
          when "--watch-js", "--clean-js"
            package_name = process[:values].pop
            framework_package = framework_packages.select { |k, v| k.to_s == package_name }
            if framework_package.empty?
              puts "Sorry, we couldn't find the package you're looking for.".red
              puts ""

              npm_packages = framework_packages.select { |name, details| details[:npm].present? }
              puts "Please enter one of the following package names when running `bin/hack --watch-js` or `bin/hack --clean-js`:"
              npm_packages.each_with_index do |package, idx|
                puts "#{idx + 1}. #{package.first}"
              end
              exit 1
            end

            set_npm_package(process[:flag], framework_package)
          end
        end

        exit
      end
    end

    puts "Welcome! Let's get hacking.".blue

    # Adding these flags enables us to execute git commands in the gem from our starter repo.
    work_tree_flag = "--work-tree=local/bullet_train-core"
    git_dir_flag = "--git-dir=local/bullet_train-core/.git"

    if File.exist?("local/bullet_train-core")
      puts "We found the repository in `local/bullet_train-core`. We will try to use what's already there.".yellow
      puts ""

      git_status = `git #{work_tree_flag} #{git_dir_flag} status`
      unless git_status.match?("nothing to commit, working tree clean")
        puts "This package currently has uncommitted changes.".red
        puts "Please make sure the branch is clean and try again.".red
        exit
      end

      current_branch = `git #{work_tree_flag} #{git_dir_flag} branch`.split("\n").select { |branch_name| branch_name.match?(/^\*\s/) }.pop.gsub(/^\*\s/, "")
      unless current_branch == "main"
        puts "Previously on #{current_branch}.".blue
        puts "Switching local/bullet_train-core to main branch.".blue
        stream("git #{work_tree_flag} #{git_dir_flag} checkout main")
      end

      puts "Updating the main branch with the latest changes.".blue
      stream("git #{work_tree_flag} #{git_dir_flag} pull origin main")
    else
      # Use https:// URLs when using this task in Gitpod.
      stream "git clone #{(`whoami`.chomp == "gitpod") ? "https://github.com/" : "git@github.com:"}/bullet-train-co/bullet_train-core.git local/bullet_train-core"
    end

    stream("git #{work_tree_flag} #{git_dir_flag} fetch")
    stream("git #{work_tree_flag} #{git_dir_flag} branch -r")
    puts "The above is a list of remote branches.".blue
    puts "If there's one you'd like to work on, please enter the branch name and press <Enter>.".blue
    puts "If not, just press <Enter> to continue.".blue
    input = $stdin.gets.strip
    unless input.empty?
      puts "Switching to #{input.gsub("origin/", "")}".blue # TODO: Should we remove origin/ here if the developer types it?
      stream("git #{work_tree_flag} #{git_dir_flag} checkout #{input}")
    end

    # Link all of the local gems to the current Gemfile.
    puts "Now we'll try to link up the Bullet Train core repositories in the `Gemfile`.".blue
    set_core_gems("--link", nil, framework_packages)

    puts ""
    puts "Now we'll run `bundle install`.".blue
    stream "bundle install"

    puts ""
    puts "We'll restart any running Rails server now.".blue
    stream "rails restart"

    puts ""
    puts "OK, we're opening bullet_train-core in your IDE, `#{ENV["IDE"] || "code"}`. (You can configure this with `export IDE=whatever`.)".blue
    `#{ENV["IDE"] || "code"} local/bullet_train-core`
    puts ""

    puts "Bullet Train has a few npm packages, but we can only watch one at a time, so we will watch the `bullet_train` package.".blue
    puts "Any changes in your JavaScript files in this package will be recompiled as we go.".blue
    puts "Run `bin/hack --watch-js` to see which other npm packages you can watch.".blue
    puts "When you're done, you can hit <Control + C> and we'll clean all off this up.".blue
    puts ""
    # TODO: On this next line we're disabling standard for now. We should circle back and remove the comment
    # that disables standard and then try the recommendation that it makes. And test it to make sure it works.
    bt_package = framework_packages.select { |k, v| k == :bullet_train } # standard:disable Style/HashSlice
    set_npm_package("--watch-js", bt_package)

    puts ""
    puts "OK, here's a list of things this script still doesn't do you for you:".yellow
    puts "1. It doesn't clean up the repository that was cloned into `local`.".yellow
    puts "2. Unless you remove it, it won't update that repository the next time you link to it.".yellow
  end

  # Pass "--link" or "--reset" as a flag to set the gems.
  def set_core_gems(flag, link_flag_value, framework_packages)
    packages = framework_packages.keys
    gemfile_lines = File.readlines("./Gemfile")
    version_regexp = /^[\d|.]$/

    packages.each do |package|
      original_path = "gem \"#{package}\", BULLET_TRAIN_VERSION"
      local_path = "gem \"#{package}\", path: \"local/bullet_train-core/#{package}\""
      match_found = false

      new_lines = gemfile_lines.map do |line|
        if line.match?(/"#{package}"/)
          match_found = true

          if flag == "--link"
            if `cat Gemfile | grep "gem \\\"#{package}\\\", path: \\\"local/bullet_train-core/#{package}\\\""`.chomp.present?
              puts "#{package} is already linked to a checked out copy in `local` in the `Gemfile`.".green
            # We can update this later to match a regular expression at the end
            # (git: "...", require: "...", etc.), but this will do for now.
            elsif `cat Gemfile | grep "gem \\\"#{package}\\\", path:"`.chomp.present?
              puts "#{package} already has some sort of alternative source configured in the `Gemfile`.".yellow
              puts "We can't do anything with this. Sorry! We'll proceed, but you have to link this package yourself.".red
            elsif `cat Gemfile | grep "gem \\\"#{package}\\\""`.chomp.present?
              puts "#{package} is directly present in the `Gemfile`, so we'll update that line.".green

              line = if link_flag_value == "github"
                "#{line.chomp}, git: 'http://github.com/bullet-train-co/bullet_train-core.git'\n"
              elsif link_flag_value&.match?(version_regexp)
                "#{line.chomp}, \"#{link_flag_value}\"\n"
              elsif link_flag_value.present?
                link_flag_value.gsub!(/\/$/, "") # Ensure the custom path doesn't have a slash at the end.
                local_path.gsub(/path:.*/, "path: \"#{link_flag_value}/#{package}\"\n")
              else
                line.gsub(original_path, local_path)
              end
            end
          elsif flag == "--reset"
            if line.match?(/bullet_train/)
              line.gsub!(/,.*$/, ", BULLET_TRAIN_VERSION")
            end
            puts "Resetting '#{package}' package in the Gemfile...".blue
          end
        end
        line
      end

      # Add/Remove any packages that aren't primarily in the Gemfile.
      if flag == "--link"
        unless match_found
          puts "Could not find #{package}. Adding to the end of the Gemfile.".blue
          new_lines << if link_flag_value == "github"
            "#{original_path.chomp}, git: 'http://github.com/bullet-train-co/bullet_train-core.git'\n"
          elsif link_flag_value&.match?(version_regexp)
            "#{original_path.chomp}, \"#{link_flag_value}\"\n"
          elsif link_flag_value
            "#{original_path.chomp}, path: \"#{link_flag_value}/#{package}\"\n"
          else
            "#{local_path}\n"
          end
        end
      elsif flag == "--reset"
        gem_regexp = /bullet_train-[a-z|A-Z_-]+/
        while new_lines.last.match?(gem_regexp)
          puts "Removing #{new_lines.last.scan(gem_regexp).first} from the Gemfile.".yellow
          new_lines.pop
        end
      end

      gemfile_lines = new_lines
    end

    File.write("./Gemfile", gemfile_lines.join)
  end

  def set_npm_package(flag, package)
    package.each do |name, details|
      if flag == "--watch-js"
        puts "Make sure your server is running before proceeding. When you're ready, press <Enter>".blue
        $stdin.gets.strip

        puts "Linking JavaScript for #{name}".blue
        stream "cd local/bullet_train-core/#{name} && yarn install && npm_config_yes=true && npx yalc link && cd ../../.. && npm_config_yes=true npx yalc link \"#{details[:npm]}\""
        puts "#{name} has been linked.".blue
        puts "Preparing to watch changes.".blue
        stream "yarn --cwd local/bullet_train-core/#{name} watch"

        # Provide a help message after the developer kills the process with `Ctrl + C`.
        puts "Run `bin/hack --clean-js #{name}` to revert to using the original npm package in your application.".blue
      elsif flag == "--clean-js"
        puts "Going back to using original `#{name}` npm package in application.".blue
        puts ""

        system "yarn yalc remove #{details[:npm]}"
        system "yarn add #{details[:npm]}"
      end
    end
  end
end
