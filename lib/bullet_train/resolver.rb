module BulletTrain
  class Resolver
    def initialize(needle)
      @needle = needle
    end

    def run(eject: false, open: false, force: false)
      # Try to figure out what kind of thing they're trying to look up.
      source_file = calculate_source_file_details

      if source_file[:absolute_path]
        if source_file[:package_name].present?
          puts ""
          puts "Absolute path:".green
          puts "  #{source_file[:absolute_path]}".green
          puts ""
          puts "Package name:".green
          puts "  #{source_file[:package_name]}".green
          puts ""
        else
          puts ""
          puts "Project path:".green
          puts "  #{source_file[:project_path]}".green
          puts ""
          puts "Note: If this file was previously ejected from a package, we can no longer see which package it came from. However, it should say at the top of the file where it was ejected from.".yellow
          puts ""
        end

        if eject
          if source_file[:package_name]
            if File.exist?(source_file[:project_path]) && !force
              return puts "Can't eject! `#{source_file[:project_path]}` already exists!\n".red
            else
              `mkdir -p #{source_file[:project_path].split("/")[0...-1].join("/")}`
              puts "Ejecting `#{source_file[:absolute_path]}` to `#{source_file[:project_path]}`".green
              File.open("#{source_file[:project_path]}", "w+") do |file|
                file.puts "# Ejected from `#{source_file[:package_name]}`.\n\n"
              end
              `cat #{source_file[:absolute_path]} >> #{source_file[:project_path]}`.strip
            end

            # Just in case they try to open the file, open it from the new location.
            source_file[:absolute_path] = source_file[:project_path]

            # TODO Do we need to restart the Rails server to pick up the new file?
          else
            puts "This file is already in the local project directory. Skipping ejection.".yellow
            puts ""
          end
        end

        if open
          path = source_file[:package_name] ? source_file[:absolute_path] : "#{source_file[:project_path]}"
          puts "Opening `#{path}`.\n".green
          exec "open #{path}"
        end
      else
        puts "Couldn't resolve `#{@needle}`.".red
      end
      if open
      end
    end

    def calculate_source_file_details
      result = {
        absolute_path: nil,
        project_path: nil,
        package_name: nil,
      }

      result[:absolute_path] = if class?
        Object.const_source_location(@needle).first
      else
        nil
      end

      if result[:absolute_path]
        # Try to calculate which package the file is from, and what it's path is within that project.
        ["app", "config", "lib"].each do |directory|
          regex = /\/#{directory}\//
          if result[:absolute_path].match?(regex)
            project_path = "./#{directory}/#{result[:absolute_path].rpartition(regex).last}"
            package_name = result[:absolute_path].rpartition(regex).first.split("/").last
            # If the "package name" is actually just the local project directory.
            if package_name == `pwd`.chomp.split("/").last
              package_name = nil
            end

            result[:project_path] = project_path
            result[:package_name] = package_name
          end
        end
      end

      result
    end

    def url?
      @needle.match?(/https?:\/\//)
    end

    def class?
      begin
        @needle.constantize
        return true
      rescue NameError => _
        return false
      end

      # Literally any class they could want to look at would be namespaced.
      @needle.match?(/::/)
    end

    def file?
      @needle.match?(/.rb$/) || @needle.match?(/.erb$/)
    end
  end
end
