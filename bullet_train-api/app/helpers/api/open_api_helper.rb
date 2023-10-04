module Api
  module OpenApiHelper
    def indent(string, count)
      lines = string.lines
      first_line = lines.shift
      lines = lines.map { |line| ("  " * count).to_s + line }
      lines.unshift(first_line).join.html_safe
    end

    def current_model
      @model_stack.last
    end

    def for_model(model)
      @model_stack ||= []
      @model_stack << model
      result = yield
      @model_stack.pop
      result
    end

    def gem_paths
      @gem_paths ||= `bundle show --paths`.lines.map { |gem_path| gem_path.chomp }
    end

    def automatic_paths_for(model, parent, except: [])
      output = render("api/#{@version}/open_api/shared/paths", except: except)
      output = Scaffolding::Transformer.new(model.name, [parent&.name]).transform_string(output).html_safe

      custom_actions_file_path = "api/#{@version}/open_api/#{model.name.underscore.pluralize}/paths"
      output += render(custom_actions_file_path) if lookup_context.exists?(custom_actions_file_path, [], true)

      # There are some placeholders specific to this method that we still need to transform.
      model_symbol = model.name.underscore.tr("/", "_").to_sym

      FactoryBot::ExampleBot::REST_METHODS.each do |method|
        if (code = FactoryBot.send(method, model_symbol, version: @version))
          output.gsub!("🚅 #{method}", code)
        end
      end

      indent(output, 1)
    end

    def automatic_components_for(model, locals: {})
      path = "app/views/api/#{@version}"
      paths = [path, "app/views"] + gem_paths.product(%W[/#{path} /app/views]).map(&:join)

      jbuilder = Jbuilder::Schema.renderer(paths, locals: {
        # If we ever get to the point where we need a real model here, we should implement an example team in seeds that we can source it from.
        model.name.underscore.split("/").last.to_sym => model.new,
        # Same here, if we ever need this to be a real object, this should be `test@example.com` with an `SecureRandom.hex` password.
        :current_user => User.new
      }.merge(locals))

      factory_path = "test/factories/#{model.model_name.collection}.rb"
      cache_key = [:example, model.model_name.param_key, File.ctime(factory_path)]
      example = Rails.cache.fetch(cache_key) do
        FactoryBot.example(model.model_name.param_key.to_sym)
      end

      schema_json = jbuilder.json(
        example || model.new,
        title: I18n.t("#{model.name.underscore.pluralize}.label"),
        # TODO Improve this. We don't have a generic description for models we can use here.
        description: I18n.t("#{model.name.underscore.pluralize}.label")
      )

      attributes_output = JSON.parse(schema_json)

      # Add "Attributes" part to $ref's
      update_ref_values!(attributes_output)

      # Rails attachments aren't technically attributes in a model,
      # so we add the attributes manually to make them available in the API.
      if model.attachment_reflections.any?
        model.attachment_reflections.each do |reflection|
          attribute_name = reflection.first

          attributes_output["properties"][attribute_name] = {
            "type" => "object",
            "description" => attribute_name.titleize.to_s
          }

          attributes_output["example"].merge!({attribute_name.to_s => nil})
        end
      end

      if has_strong_parameters?("Api::#{@version.upcase}::#{model.name.pluralize}Controller".constantize)
        strong_params_module = "Api::#{@version.upcase}::#{model.name.pluralize}Controller::StrongParameters".constantize
        strong_parameter_keys = BulletTrain::Api::StrongParametersReporter.new(model, strong_params_module).report
        if strong_parameter_keys.last.is_a?(Hash)
          strong_parameter_keys += strong_parameter_keys.pop.keys
        end

        parameters_output = JSON.parse(schema_json)
        parameters_output["required"].select! { |key| strong_parameter_keys.include?(key.to_sym) }
        parameters_output["properties"].select! { |key| strong_parameter_keys.include?(key.to_sym) }
        parameters_output["example"]&.select! { |key, value| strong_parameter_keys.include?(key.to_sym) && value.present? }

        (
          indent(attributes_output.to_yaml.gsub("---", "#{model.name.gsub("::", "")}Attributes:"), 3) +
            indent("    " + parameters_output.to_yaml.gsub("---", "#{model.name.gsub("::", "")}Parameters:"), 3)
        ).html_safe
      else

        indent(attributes_output.to_yaml.gsub("---", "#{model.name.gsub("::", "")}Attributes:"), 3)
          .html_safe
      end
    end

    def paths_for(model)
      for_model model do
        indent(render("api/#{@version}/open_api/#{model.name.underscore.pluralize}/paths"), 1)
      end
    end

    private

    def has_strong_parameters?(controller)
      methods = controller.action_methods
      methods.include?("create") || methods.include?("update")
    end

    def update_ref_values!(hash)
      hash.each do |key, value|
        if key == "$ref" && value.is_a?(String) && !value.include?("Attributes")
          # Extract the part after "#/components/schemas/"
          schema_part = value.split("#/components/schemas/").last

          # Capitalize each part and join them
          camelized_schema = schema_part.split("/").map(&:camelize).join

          # Update the value
          hash[key] = "#/components/schemas/#{camelized_schema}Attributes"
        elsif value.is_a?(Hash)
          # Recursively call the method for nested hashes
          update_ref_values!(value)
        elsif value.is_a?(Array)
          # Recursively call the method for each hash in the array
          value.each do |item|
            update_ref_values!(item) if item.is_a?(Hash)
          end
        end
      end
    end
  end
end
