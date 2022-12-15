require "io/wait"

namespace :bt do
  desc "Symlink registered gems in `./tmp/gems` so their views, etc. can be inspected by Tailwind CSS."
  task link: :environment do
    if Dir.exist?("tmp/gems")
      puts "Removing previously linked gems."
      `rm -f tmp/gems/*`
    else
      if File.exist?("tmp/gems")
        raise "A file named `tmp/gems` already exists? It has to be removed before we can create the required directory."
      end

      puts "Creating 'tmp/gems' directory."
      `mkdir tmp/gems`
    end

    `touch tmp/gems/.keep`

    BulletTrain.linked_gems.each do |linked_gem|
      target = `bundle show #{linked_gem}`.chomp
      if target.present?
        puts "Linking '#{linked_gem}' to '#{target}'."
        `ln -s #{target} tmp/gems/#{linked_gem}`
      end
    end
  end
end

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
      $stdin.getc while $stdin.ready?

      # Extract absolute paths from annotated views.
      if input =~ /<!-- BEGIN (.*) -->/
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

  task :develop, [:all_options] => :environment do |t, arguments|
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

    # Process any flags that were passed.
    if arguments[:all_options].present?
      flags_with_values = []

      arguments[:all_options].split(/\s+/).each do |option|
        if option.match?(/^--/)
          flags_with_values << {flag: option.gsub(/^--/, "").to_sym, values: []}
        else
          flags_with_values.last[:values] << option
        end
      end

      if flags_with_values.any?
        flags_with_values.each do |process|
          if process[:flag] == :link || process[:flag] == :reset
            packages = process[:values]

            gemfile_lines = File.readlines("./Gemfile")
            new_lines = gemfile_lines.map do |line|
              packages.each do |package|
                if line.match?(package)
                  original_path = "gem \"bullet_train#{"-" + package unless package == "base"}\""
                  local_path = "gem \"bullet_train#{"-" + package unless package == "base"}\", path: \"local/bullet_train-#{package}\""

                  case process[:flag]
                  when :link
                    line.gsub!(original_path, local_path)
                    puts "Setting local '#{package}' package to the Gemfile...".blue
                    break
                  when :reset
                    line.gsub!(local_path, original_path)
                    puts "Resetting '#{package}' package in the Gemfile...".blue
                    break
                  end
                end
              end

              line
            end

            File.write("./Gemfile", new_lines.join)
            system "bundle install"
          end
        end

        exit
      end
    end

    framework_packages = I18n.t("framework_packages")

    puts "Which framework package do you want to work on?".blue
    puts ""
    framework_packages.each do |gem, details|
      puts "  #{framework_packages.keys.find_index(gem) + 1}. #{gem}".blue
    end
    puts ""
    puts "Enter a number below and hit <Enter>:".blue
    number = $stdin.gets.chomp

    gem = framework_packages.keys[number.to_i - 1]

    if gem
      details = framework_packages[gem]
      package = details[:git].split("/").last

      puts "OK! Let's work on `#{gem}` together!".green
      puts ""

      if File.exist?("local/#{package}")
        puts "We found the repository in `local/#{package}`. We will try to use what's already there.".yellow
        puts ""

        # Adding these flags enables us to execute git commands in the gem from our starter repo.
        work_tree_flag = "--work-tree=local/#{package}"
        git_dir_flag = "--git-dir=local/#{package}/.git"

        git_status = `git #{work_tree_flag} #{git_dir_flag} status`
        unless git_status.match?("nothing to commit, working tree clean")
          puts "This package currently has uncommitted changes.".red
          puts "Please make sure the branch is clean and try again.".red
          exit
        end

        current_branch = `git #{work_tree_flag} #{git_dir_flag} branch`.split("\n").select { |branch_name| branch_name.match?(/^\*\s/) }.pop.gsub(/^\*\s/, "")
        unless current_branch == "main"
          puts "Previously on #{current_branch}.".blue
          puts "Switching local/#{package} to main branch.".blue
          stream("git #{work_tree_flag} #{git_dir_flag} checkout main")
        end

        puts "Updating the main branch with the latest changes.".blue
        stream("git #{work_tree_flag} #{git_dir_flag} pull origin main")
      else
        # Use https:// URLs when using this task in Gitpod.
        stream "git clone #{(`whoami`.chomp == "gitpod") ? "https://github.com/" : "git@github.com:"}#{details[:git]}.git local/#{package}"
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

      glob = if package == "bullet_train-core"
        ", glob: \"#{gem}/#{gem}.gemspec\""
      end

      puts ""
      puts "Now we'll try to link up that repository in the `Gemfile`.".blue
      if `cat Gemfile | grep "gem \\\"#{gem}\\\", path: \\\"local/#{package}\\\""`.chomp.present?
        puts "This gem is already linked to a checked out copy in `local` in the `Gemfile`.".green
      elsif `cat Gemfile | grep "gem \\\"#{gem}\\\","`.chomp.present?
        puts "This gem already has some sort of alternative source configured in the `Gemfile`.".yellow
        puts "We can't do anything with this. Sorry! We'll proceed, but you have to link this package yourself.".red
      elsif `cat Gemfile | grep "gem \\\"#{gem}\\\""`.chomp.present?
        puts "This gem is directly present in the `Gemfile`, so we'll update that line.".green
        text = File.read("Gemfile")
        new_contents = text.gsub(/gem "#{gem}"/, "gem \"#{gem}\", path: \"local/#{package}\"#{glob}")
        File.open("Gemfile", "w") { |file| file.puts new_contents }
      else
        puts "This gem isn't directly present in the `Gemfile`, so we'll add it temporarily.".green
        File.open("Gemfile", "a+") { |file|
          file.puts
          file.puts "gem \"#{gem}\", path: \"local/#{package}\"#{glob} # Added by `bin/develop`."
        }
      end

      puts ""
      puts "Now we'll run `bundle install`.".blue
      stream "bundle install"

      puts ""
      puts "We'll restart any running Rails server now.".blue
      stream "rails restart"

      puts ""
      puts "OK, we're opening that package in your IDE, `#{ENV["IDE"] || "code"}`. (You can configure this with `export IDE=whatever`.)".blue
      `#{ENV["IDE"] || "code"} local/#{package}`

      puts ""
      if details[:npm]
        puts "This package also has an npm package, so we'll link that up as well.".blue
        stream "cd local/#{gem} && yarn install && npm_config_yes=true npx yalc link && cd ../.. && npm_config_yes=true npx yalc link \"#{details[:npm]}\""

        puts ""
        puts "And now we're going to watch for any changes you make to the JavaScript and recompile as we go.".blue
        puts "When you're done, you can hit <Control + C> and we'll clean all off this up.".blue
        stream "cd local/#{gem} && yarn watch"
      else
        puts "This package has no npm package, so we'll just hang out here and do nothing. However, when you hit <Enter> here, we'll start the process of cleaning all of this up.".blue
        $stdin.gets
      end

      puts ""
      puts "OK, here's a list of things this script still doesn't do you for you:".yellow
      puts "1. It doesn't clean up the repository that was cloned into `local`.".yellow
      puts "2. Unless you remove it, it won't update that repository the next time you link to it.".yellow
    else
      puts ""
      puts "Invalid option, \"#{number}\". Try again.".red
    end
  end
end
