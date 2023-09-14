require "scaffolding"
require "scaffolding/file_manipulator"

require "faraday"
require "tempfile"

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

    desc "Bump the current version of application's API"
    task push_to_redocly: :environment do
      include Rails.application.routes.url_helpers

      raise "You need to set REDOCLY_ORGANIZATION_ID in your environment. You can fetch it from the URL when you're on your Redocly dashboard." unless ENV["REDOCLY_ORGANIZATION_ID"].present?
      raise "You need to set REDOCLY_API_KEY in your environment. You can create one at https://app.redocly.com/org/#{ENV["REDOCLY_ORGANIZATION_ID"]}/settings/api-keys ." unless ENV["REDOCLY_API_KEY"].present?

      # Create a new Faraday connection
      conn = Faraday.new(api_url(version: BulletTrain::Api.current_version))

      # Fetch the file
      response = conn.get

      # Check if the request was successful
      if response.status == 200
        # Create a temp file
        temp_file = Tempfile.new(["openapi-", ".yaml"])

        # Write the file content to the temp file
        temp_file.binmode
        temp_file.write(response.body)
        temp_file.rewind

        # Close and delete the temp file when the script exits
        temp_file.close
        puts "File downloaded and saved to: #{temp_file.path}"

        puts `echo "#{ENV["REDOCLY_API_KEY"]}" | redocly login`

        puts `redocly push #{temp_file.path} "@#{ENV["REDOCLY_ORGANIZATION_ID"]}/#{I18n.t("application.name")}@#{BulletTrain::Api.current_version}" --public --upsert`

        temp_file.unlink
      else
        puts "Failed to download the OpenAPI Document. Status code: #{response.status}"
      end
    end

    desc "Export the OpenAPI schema for the application"
    task export_openapi_schema: :environment do
      @version = BulletTrain::Api.current_version
      dir = "tmp/openapi"
      Dir.mkdir(dir) unless File.exist?(dir)
      File.open("#{dir}/openapi-#{Time.now.strftime("%Y%m%d-%H%M%S")}.yaml", "w+") do |f|
        f.binmode
        f.write(
          ApplicationController.renderer.render(
            template: "api/#{@version}/open_api/index",
            layout: false,
            format: :text,
            assigns: {version: @version}
          )
        )
      end
    end
  end
end
