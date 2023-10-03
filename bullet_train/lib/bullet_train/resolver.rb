require "io/wait"

module BulletTrain
  class Resolver
    include I18n::Backend::Flatten

    def initialize(needle)
      @needle = needle
    end

    def run(eject: false, open: false, force: false, interactive: false)
      # Try to figure out what kind of thing they're trying to look up.
      source_file = calculate_source_file_details
      source_file[:relative_path] = nil

      if source_file[:absolute_path]
        puts ""
        puts "Absolute path:".green
        puts "  #{source_file[:absolute_path]}".green
        puts ""

        source_file[:relative_path] = source_file[:absolute_path].split(/(?=#{source_file[:package_name]})/).pop

        if source_file[:package_name].present?
          puts "Package name:".green
          puts "  #{source_file[:package_name]}".green
        else
          puts "Note: If this file was previously ejected from a package, we can no longer see which package it came from. However, it should say at the top of the file where it was ejected from.".yellow
        end
        puts ""

        if interactive && !eject
          puts "\nWould you like to eject the file into the local project? (y/n)\n"
          input = $stdin.gets
          $stdin.getc while $stdin.ready?
          if input.first.downcase == "y"
            eject = true
          end
        end

        if eject
          if source_file[:package_name]
            if File.exist?(source_file[:project_path]) && !force
              return puts "Can't eject! `#{source_file[:project_path]}` already exists!\n".red
            else
              `mkdir -p #{source_file[:project_path].split("/")[0...-1].join("/")}`
              puts "Ejecting `#{source_file[:absolute_path]}` to `#{source_file[:project_path]}`".green
              File.open((source_file[:project_path]).to_s, "w+") do |file|
                case source_file[:project_path].split(".").last
                when "rb", "yml"
                  file.puts "# Ejected from `#{source_file[:relative_path] || source_file[:package_name]}`.\n\n"
                when "erb"
                  file.puts "<% # Ejected from `#{source_file[:relative_path] || source_file[:package_name]}`. %>\n\n"
                end
              end
              `cat #{source_file[:absolute_path]} >> #{source_file[:project_path]}`.strip

              # Look for showcase preview.
              file_name = source_file[:absolute_path].split("/").last
              showcase_partials = Dir.glob(`bundle show bullet_train-themes-light`.chomp + "/app/views/showcase/**/*.html.erb")
              showcase_preview = showcase_partials.find { _1.end_with?(file_name) }
              if showcase_preview
                puts "Ejecting showcase preview for #{source_file[:relative_path]}"
                partial_relative_path = showcase_preview.scan(/(?=app\/views\/showcase).*/).last
                directory = partial_relative_path.split("/")[0..-2].join("/")
                FileUtils.mkdir_p(directory)
                FileUtils.touch(partial_relative_path)
                `cp #{showcase_preview} #{partial_relative_path}`
              end
            end

            # Just in case they try to open the file, open it from the new location.
            source_file[:absolute_path] = source_file[:project_path]
          else
            puts "This file is already in the local project directory. Skipping ejection.".yellow
            puts ""
          end
        end

        if interactive && !open
          puts "\nWould you like to open `#{source_file[:absolute_path]}`? (y/n)\n"
          input = $stdin.gets
          $stdin.getc while $stdin.ready?
          if input.first.downcase == "y"
            open = true
          end
        end

        if open
          path = source_file[:package_name] ? source_file[:absolute_path] : (source_file[:project_path]).to_s
          puts "Opening `#{path}`.\n".green

          # TODO: Use TerminalCommands to open this file
          open_command = `which open`.present? ? "open" : "xdg-open"
          exec "#{open_command} #{source_file[:absolute_path]}"
        end
      else
        puts "Couldn't resolve `#{@needle}`.".red
      end
    end

    def calculate_source_file_details
      result = {
        absolute_path: nil,
        project_path: nil,
        package_name: nil,
      }

      result[:absolute_path] = file_path || class_path || locale_path || partial_path

      # If we get the partial resolver template itself, that means we couldn't find the file.
      if result[:absolute_path].match?("app/views/bullet_train/partial_resolver.html.erb") || result[:absolute_path].nil?
        puts "We could not resolve the value you're looking for: #{@needle}".red
        puts ""
        puts "If you're looking for a partial, please try passing the partial string in either of the following two ways:"
        puts "1. Without underscore and extention: ".blue + "bin/resolve shared/attributes/code"
        puts "2. Literal path with package name: ".blue + "bin/resolve bullet_train-themes/app/views/themes/base/attributes/_code.html.erb"
        puts ""
        puts "If you're looking for a locale, the key might not be implemented yet."
        puts "Try adding your own custom text for the key to your locale file and try again."
        exit
      end

      if result[:absolute_path]
        if result[:absolute_path].include?("/bullet_train")
          # This Regular Expression covers gem versions like bullet_train-1.2.26,
          # and hashed versions of branches on GitHub like bullet_train-core-b00a02bd513c.
          gem_version_regex = /[a-z|\-._0-9]*/
          regex = /#{"bullet_train-core#{gem_version_regex}" if result[:absolute_path].include?("bullet_train-core")}\/bullet_train#{gem_version_regex}.*/
          base_path = result[:absolute_path].scan(regex).pop

          # Try to calculate which package the file is from, and what it's path is within that project.
          ["app", "config", "lib"].each do |directory|
            regex = /\/#{directory}\//
            if base_path.match?(regex)
              project_path = "./#{directory}/#{base_path.rpartition(regex).last}"
              package_name = base_path.rpartition(regex).first.split("/").last
              # If the "package name" is actually just the local project directory.
              if package_name == `pwd`.chomp.split("/").last
                package_name = nil
              end

              result[:project_path] = project_path
              result[:package_name] = package_name
            end
          end
        end
      end
      result
    end

    def url?
      @needle.match?(/https?:\/\//)
    end

    def class_path
      @needle.constantize
      Object.const_source_location(@needle).first
    rescue NameError => _
      false
    end

    def partial_path
      # Parse literal partial strings.
      if @needle.match?(/\.html\.erb$/)
        partial_parts = @needle.split("/")

        # TODO: We should probably just default to raising an error if the developer
        # provides a literal partial string without the name of the package it's coming from.
        if partial_parts.size <= 3
          # If the string looks something like "shared/attributes/_code.html.erb",
          # all we need to do is change it to "shared/attributes/code"
          partial_parts.last.gsub!(/(_)|(\.html\.erb)/, "")
          @needle = partial_parts.join("/")
        elsif @needle.match?(/bullet_train/)
          # If it's a full path, we need to make sure we're getting it from the right package.
          _, partial_view_package, partial_path_without_package = @needle.partition(/(bullet_train-core\/)?bullet_train[a-z|\-._0-9]*/)

          # Pop off `bullet_train-core` and the gem's version so we can call `bundle show` correctly.
          partial_view_package.gsub!("bullet_train-core/", "")
          partial_view_package.gsub!(/[-|.0-9]*$/, "") if partial_view_package.match?(/[-|.0-9]*$/)

          local_package_path = `bundle show #{partial_view_package}`.chomp
          return local_package_path + partial_path_without_package
        else
          puts "You passed the absolute path for a partial literal, but we couldn't find the package name in the string:".red
          puts "`#{@needle}`".red
          puts ""
          puts "Check the string one more time to see if the package name is there."
          puts "i.e.: bullet_train-1.2.24/app/views/layouts/devise.html.erb".blue
          puts ""
          puts "If you're not sure what the package name is, run `bin/resolve --interactive`, follow the prompt, and pass the annotated path."
          puts "i.e.: <!-- BEGIN /your/local/path/bullet_train-base/app/views/layouts/devise.html.erb -->".blue
          exit
        end
      end

      begin
        annotated_path = ApplicationController.render(template: "bullet_train/partial_resolver", layout: nil, assigns: {needle: @needle}).lines[1].chomp
      rescue ActionView::Template::Error => e
        # This is a really hacky way to get the file name, but the reason we're getting an error in the first place is because
        # the partial requires locals that we aren't providing in the ApplicationController.render call above,
        # resulting in an undefined local variable error. We do however get the file name, which we can pass back to the developer.
        return e.file_name
      end

      if annotated_path =~ /<!-- BEGIN (\S*) -->/
        # If the developer enters a partial that is in bullet_train-base like devise/shared/oauth or devise/shared/links,
        # it will return a string starting with app/ so we simply point them to the file in this repository.
        if annotated_path.match?(/^<!-- BEGIN app/) && !ejected_theme?
          gem_path = `bundle show bullet_train`.chomp
          "#{gem_path}/#{$1}"
        else
          $1
        end
      else
        raise "It looks like `config.action_view.annotate_rendered_view_with_filenames` isn't enabled?"
      end
    rescue ActionView::Template::Error => _
      nil
    end

    def file_path
      # We don't have to do anything here... the absolute path is what we're passed, and we just pass it back.
      if @needle[0] == "/"
        @needle
      end
    end

    def locale_path
      # This is a complete list of translation files provided by this app or any linked Bullet Train packages.
      (["#{Rails.root}/config/locales"] + `find ./tmp/gems/*`.lines.map(&:strip).map { |link| File.readlink(link) + "/config/locales" }).each do |locale_source|
        if File.exist?(locale_source)
          `find -L #{locale_source} | grep ".yml"`.lines.map(&:strip).each do |file_path|
            yaml = YAML.load_file(file_path, aliases: true)
            translations = flatten_translations(nil, yaml, nil, false)
            if translations[@needle.to_sym].present?
              return file_path
            end
          end
        end
      end

      nil
    end

    def ejected_theme?
      current_theme_symbol = File.read("#{Rails.root}/app/helpers/application_helper.rb").split("\n").find { |str| str.match?(/\s+:.*/) }
      current_theme = current_theme_symbol.delete(":").strip
      current_theme != "light" && Dir.exist?("#{Rails.root}/app/assets/stylesheets/#{current_theme}")
    end
  end
end
