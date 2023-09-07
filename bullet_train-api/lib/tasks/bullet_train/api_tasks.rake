require "scaffolding"
require "scaffolding/file_manipulator"

namespace :bullet_train do
  namespace :api do
    desc "Bump the current version of application's API"
    task :bump_version do
      # Calculate new version.
      initializer_content = File.new("config/initializers/api.rb").readline
      previous_version = initializer_content.scan(/v\d+/).pop
      new_version_int = previous_version.scan(/\d+/).pop.to_i + 1
      new_version = "v#{new_version_int}"

      # Update initializer.
      File.write("config/initializers/api.rb", initializer_content.gsub(previous_version, new_version))

      [
        "app/controllers/api/#{new_version}",
        "app/views/api/#{new_version}",
        "test/controllers/api/#{new_version}"
      ].each do |dir|
        Dir.mkdir(dir)
      end

      files_to_update = [
        "config/routes/api/#{previous_version}.rb",
        Dir.glob("app/controllers/api/#{previous_version}/**/*.rb") +
          Dir.glob("app/views/api/#{previous_version}/**/*.json.jbuilder") +
          Dir.glob("test/controllers/api/#{previous_version}/**/*.rb")
      ].flatten

      files_to_update.each do |file_name|
        previous_file_contents = File.open(file_name).readlines
        new_file_name = file_name.gsub(previous_version, new_version)

        updated_file_contents = previous_file_contents.map do |line|
          if line.match?(previous_version)
            line.gsub(previous_version, new_version)
          else
            line.gsub("Api::#{previous_version.upcase}", "Api::#{new_version.upcase}")
          end
        end

        # We can't create new files unless each directory under #{api/previous_version}
        # has been created under the new api directory. For example, we have to create
        # the `projects` directory before we can create the file `api/v2/projects/pages.json.jbuilder.`
        new_version_dir, dir_hierarchy = new_file_name.split(/(?<=#{new_version})\//)
        if dir_hierarchy.present? && dir_hierarchy.match?("/")
          dir_hierarchy = dir_hierarchy.split("/")
          dir_hierarchy.inject(new_version_dir) do |base, child_dir_or_file|
            # Stop making new directories if the string has an extention like ".rb"
            break if child_dir_or_file.match?(/\./)

            new_hierarchy = "#{base}/#{child_dir_or_file}"
            Dir.mkdir(new_hierarchy) unless Dir.exist?(new_hierarchy)
            new_hierarchy
          end
        end
        Scaffolding::FileManipulator.write(new_file_name, updated_file_contents)
      end

      # Here we make sure config/api/#{new_version}.rb is called from within the main routes file.
      previous_file_contents = File.open("config/routes.rb").readlines
      updated_file_contents = previous_file_contents.map do |line|
        if line.match?("draw \"api/#{previous_version}\"")
          new_version_draw_line = line.gsub(previous_version, new_version)
          line + new_version_draw_line
        else
          line
        end
      end
      Scaffolding::FileManipulator.write("config/routes.rb", updated_file_contents)

      # Update application locale for each locale that exists.
      I18n.available_locales.each do |lang|
        file = "config/locales/#{lang}/application.#{lang}.yml"
        transformer = Scaffolding::Transformer.new("", "")

        if File.exist?(file)
          transformer.add_line_to_file(
            file,
            "#{new_version_int}: #{new_version.upcase}",
            Scaffolding::Transformer::RUBY_NEW_API_VERSION_HOOK,
            prepend: true
          )
        end
      end

      puts "Finished bumping to #{new_version}"
    end
  end
end
