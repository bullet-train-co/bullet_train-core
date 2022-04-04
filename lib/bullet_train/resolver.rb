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

      if source_file[:absolute_path]
        puts ""
        if source_file[:package_name].present?
          puts "Absolute path:".green
          puts "  #{source_file[:absolute_path]}".green
          puts ""
          puts "Package name:".green
          puts "  #{source_file[:package_name]}".green
        else
          puts "Project path:".green
          puts "  #{source_file[:project_path]}".green
          puts ""
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
                  file.puts "# Ejected from `#{source_file[:package_name]}`.\n\n"
                when "erb"
                  file.puts "<% # Ejected from `#{source_file[:package_name]}`. %>\n\n"
                end
              end
              `cat #{source_file[:absolute_path]} >> #{source_file[:project_path]}`.strip
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
          exec "open #{path}"
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

      result[:absolute_path] = class_path || partial_path || locale_path || file_path

      if result[:absolute_path]
        base_path = "bullet_train" + result[:absolute_path].split("/bullet_train").last

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
      annotated_path = ApplicationController.render(template: "bullet_train/partial_resolver", layout: nil, assigns: {needle: @needle}).lines[1].chomp
      if annotated_path =~ /<!-- BEGIN (.*) -->/
        $1
      else
        raise "It looks like `config.action_view.annotate_rendered_view_with_filenames` isn't enabled?"
      end
    rescue ActionView::Template::Error => _
      nil
    end

    def file_path
      # We don't have to do anything here... the absolute path is what we're passed, and we just pass it back.
      @needle
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
  end
end
