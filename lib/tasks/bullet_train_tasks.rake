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
      warn "\n🚅 Usage: `bin/resolve [path, partial, or URL] (--eject) (--open)`\n".blue
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

    # TODO Extract this into a YAML file.
    framework_packages = {
      "bullet_train" => {
        git: "bullet-train-co/bullet_train-base",
        npm: "@bullet-train/bullet-train"
      },
      "bullet_train-api" => {
        git: "bullet-train-co/bullet_train-api",
      },
      "bullet_train-fields" => {
        git: "bullet-train-co/bullet_train-fields",
        npm: "@bullet-train/fields"
      },
      "bullet_train-has_uuid" => {
        git: "bullet-train-co/bullet_train-has_uuid",
      },
      "bullet_train-incoming_webhooks" => {
        git: "bullet-train-co/bullet_train-incoming_webhooks",
      },
      "bullet_train-integrations" => {
        git: "bullet-train-co/bullet_train-integrations",
      },
      "bullet_train-integrations-stripe" => {
        git: "bullet-train-co/bullet_train-base-integrations-stripe",
      },
      "bullet_train-obfuscates_id" => {
        git: "bullet-train-co/bullet_train-obfuscates_id",
      },
      "bullet_train-outgoing_webhooks" => {
        git: "bullet-train-co/bullet_train-outgoing_webhooks",
      },
      "bullet_train-outgoing_webhooks-core" => {
        git: "bullet-train-co/bullet_train-outgoing_webhooks-core",
      },
      "bullet_train-scope_questions" => {
        git: "bullet-train-co/bullet_train-scope_questions",
      },
      "bullet_train-scope_validator" => {
        git: "bullet-train-co/bullet_train-scope_validator",
      },
      "bullet_train-sortable" => {
        git: "bullet-train-co/bullet_train-sortable",
        npm: "@bullet-train/bullet-train-sortable"
      },
      "bullet_train-super_scaffolding" => {
        git: "bullet-train-co/bullet_train-super_scaffolding",
      },
      "bullet_train-super_load_and_authorize_resource" => {
        git: "bullet-train-co/bullet_train-super_load_and_authorize_resource",
      },
      "bullet_train-themes" => {
        git: "bullet-train-co/bullet_train-themes",
      },
      "bullet_train-themes-base" => {
        git: "bullet-train-co/bullet_train-themes-base",
      },
      "bullet_train-themes-light" => {
        git: "bullet-train-co/bullet_train-themes-light",
      },
      "bullet_train-themes-tailwind_css" => {
        git: "bullet-train-co/bullet_train-themes-tailwind_css",
      },
    }

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

      puts "OK! Let's work on `#{gem}` together!".green
      puts ""
      puts "First, we're going to clone a copy of the package repository.".blue

      # TODO Prompt whether they want to check out their own forked version of the repository.

      if File.exist?("local/#{gem}")
        puts "Can't clone into `local/#{gem}` because it already exists. We will try to use what's already there.".yellow
        puts "However, it will be up to you to make sure that working copy of the repository is in a clean state and checked out to the `main` branch or whatever you want to work on.".yellow
        puts "Hit <Enter> to continue.".blue
        $stdin.gets

        # TODO We should check whether the local copy is in a clean state, and if it is, check out `main`.
        # TODO We should also pull `origin/main` to make sure we're on the most up-to-date version of the package.
      else
        # Use https:// URLs when using this task in Gitpod.
        stream "git clone #{`whoami`.chomp == "gitpod" ? "https://github.com/" : "git@github.com:"}#{details[:git]}.git local/#{gem}"
      end

      # TODO Ask them whether they want to check out a specific branch to work on. (List available remote branches.)

      puts ""
      puts "Now we'll try to link up that repository in the `Gemfile`.".blue
      if `cat Gemfile | grep "gem \\\"#{gem}\\\", path: \\\"local/#{gem}\\\""`.chomp.present?
        puts "This gem is already linked to a checked out copy in `local` in the `Gemfile`.".green
      elsif `cat Gemfile | grep "gem \\\"#{gem}\\\","`.chomp.present?
        puts "This gem already has some sort of alternative source configured in the `Gemfile`.".yellow
        puts "We can't do anything with this. Sorry! We'll proceed, but you have to link this package yourself.".red
      elsif `cat Gemfile | grep "gem \\\"#{gem}\\\""`.chomp.present?
        puts "This gem is directly present in the `Gemfile`, so we'll update that line.".green

        text = File.read("Gemfile")
        new_contents = text.gsub(/gem "#{gem}"/, "gem \"#{gem}\", path: \"local/#{gem}\"")
        File.open("Gemfile", "w") { |file| file.puts new_contents }
      else
        puts "This gem isn't directly present in the `Gemfile`, so we'll add it temporarily.".green
        File.open("Gemfile", "a+") { |file|
          file.puts
          file.puts "gem \"#{gem}\", path: \"local/#{gem}\" # Added by \`bin/develop\`."
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
      `#{ENV["IDE"] || "code"} local/#{gem}`

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
