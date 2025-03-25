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
      output = render("api/#{@version}/open_api/shared/paths", model_name: model.model_name.collection, except: except)
      output = Scaffolding::Transformer.new(model.name, [parent&.name]).transform_string(output).html_safe

      custom_actions_file_path = "api/#{@version}/open_api/#{model.model_name.collection}/paths"
      custom_output = render(custom_actions_file_path).html_safe if lookup_context.exists?(custom_actions_file_path, [], true)

      FactoryBot::ExampleBot::REST_METHODS.each do |method|
        if (code = FactoryBot.send(method, model.model_name.param_key.to_sym, version: @version))
          output.gsub!("🚅 #{method}", code)
          custom_output&.gsub!("🚅 #{method}", code)
        end
      end

      if custom_output
        merge = deep_merge(YAML.safe_load(output), YAML.safe_load(custom_output)).to_yaml.html_safe
        # YAML.safe_load escapes emojis https://github.com/ruby/psych/issues/371
        # Next line returns emojis back and removes yaml garbage
        output = merge.gsub("---", "").gsub(/\\u[\da-f]{8}/i) { |m| [m[-8..].to_i(16)].pack("U") }
      end

      indent(output, 1)
    end

    def automatic_components_for(model, **options)
      locals = options.delete(:locals) || {}

      path = "app/views/api/#{@version}"
      paths = [path, "app/views"] + gem_paths.product(%W[/#{path} /app/views]).map(&:join)

      # Transform values the same way we do for Jbuilder templates
      Jbuilder::Schema::Template.prepend ValuesTransformer

      jbuilder = Jbuilder::Schema.renderer(paths, locals: {
        # If we ever get to the point where we need a real model here, we should implement an example team in seeds that we can source it from.
        model.name.underscore.split("/").last.to_sym => model.new,
        # Same here, if we ever need this to be a real object, this should be `test@example.com` with an `SecureRandom.hex` password.
        :current_user => User.new
      }.merge(locals))

      factory_path = "test/factories/#{model.model_name.collection}.rb"
      cache_key = [:example, model.model_name.param_key, File.ctime(factory_path)]
      example = if model.name.constantize.singleton_methods.any?
        FactoryBot.example(model.model_name.param_key.to_sym)
      else
        Rails.cache.fetch(cache_key) { FactoryBot.example(model.model_name.param_key.to_sym) }
      end

      schema_json = jbuilder.json(
        example || model.new,
        title: I18n.t("#{model.name.underscore.pluralize}.label"),
        # TODO Improve this. We don't have a generic description for models we can use here.
        description: I18n.t("#{model.name.underscore.pluralize}.label")
      )

      attributes_output = JSON.parse(schema_json)

      # Allow customization of Attributes
      customize_component!(attributes_output, options[:attributes]) if options[:attributes]

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

      if has_strong_parameters?("Api::#{@version.upcase}::#{model.name.pluralize}Controller")
        strong_parameter_keys = strong_parameter_keys_for(model.name, @version)
        strong_parameter_keys_for_update = strong_parameter_keys_for(model.name, @version, "update")

        # Create separate parameter schema for create and update methods
        create_parameters_output = process_strong_parameters(model, strong_parameter_keys, schema_json, "create", **options)
        update_parameters_output = process_strong_parameters(model, strong_parameter_keys_for_update, schema_json, "update", **options)

        # We need to skip TeamParameters, UserParameters & InvitationParametersUpdate as they are not present in
        # the bullet train api schema
        if model.name == "Team" || model.name == "User"
          create_parameters_output = nil
        elsif model.name == "Invitation"
          update_parameters_output = nil
        end

        output = indent(attributes_output.to_yaml.gsub("---", "#{model.name.gsub("::", "")}Attributes:"), 3)
        output += indent("    " + create_parameters_output.to_yaml.gsub("---", "#{model.name.gsub("::", "")}Parameters:"), 3) if create_parameters_output
        output += indent("    " + update_parameters_output.to_yaml.gsub("---", "#{model.name.gsub("::", "")}ParametersUpdate:"), 3) if update_parameters_output
        output.html_safe
      else

        indent(attributes_output.to_yaml.gsub("---", "#{model.name.gsub("::", "")}Attributes:"), 3)
          .html_safe
      end
    end

    def process_strong_parameters(model, strong_parameter_keys, schema_json, method_type, **options)
      parameters_output = JSON.parse(schema_json)
      parameters_output["required"].select! { |key| strong_parameter_keys.include?(key.to_sym) }
      parameters_output["properties"].select! { |key| strong_parameter_keys.include?(key.to_sym) }
      parameters_output["example"]&.select! { |key, value| strong_parameter_keys.include?(key.to_sym) }

      # Allow customization of Parameters
      parameters_custom = options[:parameters][method_type] if options[:parameters].is_a?(Hash) && options[:parameters].key?(method_type)
      parameters_custom ||= options[:parameters]
      customize_component!(parameters_output, parameters_custom, method_type) if parameters_custom

      # We need to wrap the example parameters with the model name as expected by the API controllers
      if parameters_output["example"]
        parameters_output["example"] = {model.model_name.param_key => parameters_output["example"]}
      end

      parameters_output
    end

    def strong_parameter_keys_for(model_name, version, method_type = "create")
      strong_params_module = "::Api::#{version.upcase}::#{model_name.pluralize}Controller::StrongParameters".constantize
      strong_params_reporter = BulletTrain::Api::StrongParametersReporter.new(model_name.constantize, strong_params_module)
      strong_parameter_keys = strong_params_reporter.report(method_type)

      if strong_parameter_keys.last.is_a?(Hash)
        strong_parameter_keys += strong_parameter_keys.pop.keys
      end

      strong_parameter_keys
    end

    def paths_for(model)
      for_model model do
        indent(render("api/#{@version}/open_api/#{model.name.underscore.pluralize}/paths"), 1)
      end
    end

    def external_doc(filename)
      caller_path, line_number = caller.find { |line| line.include?(".yaml.erb:") }.split(":")
      indentation = File.readlines(caller_path)[line_number.to_i - 1].match(/^(\s*)/)[1]
      path = "app/views/api/#{@version}/open_api/docs/#{filename}.md"

      raise "Markdown file not found: #{path}" unless File.exist?(path)

      File.read(path).lines.map { |line| "  #{indentation}#{line}".rstrip }.join("\n").prepend("|\n").html_safe
    rescue Errno::ENOENT, Errno::EACCES, RuntimeError => e
      "Error loading markdown description: #{e.message}"
    end

    def description_for(model)
      external_doc "#{model.name.underscore}_description"
    end

    private

    def has_strong_parameters?(controller_name)
      "#{controller_name}::StrongParameters".constantize
      true
    rescue NameError
      false
    end

    def update_ref_values!(hash, method_type = nil)
      hash.each do |key, value|
        if key == "$ref" && value.is_a?(String) && !value.include?("Attributes#{method_type.to_s.camelize}")
          # Extract the part after "#/components/schemas/"
          schema_part = value.split("#/components/schemas/").last

          # Capitalize each part and join them
          camelized_schema = schema_part.split("/").map(&:camelize).join

          # Update the value
          hash[key] = "#/components/schemas/#{camelized_schema}Attributes#{method_type.to_s.camelize}"
        elsif value.is_a?(Hash)
          # Recursively call the method for nested hashes
          update_ref_values!(value, method_type)
        elsif value.is_a?(Array)
          # Recursively call the method for each hash in the array
          value.each do |item|
            update_ref_values!(item, method_type) if item.is_a?(Hash)
          end
        end
      end
    end

    def deep_merge(hash1, hash2)
      hash1.merge(hash2) do |_, old_val, new_val|
        if old_val.is_a?(Hash) && new_val.is_a?(Hash)
          deep_merge(old_val, new_val)
        elsif old_val.is_a?(Array) && new_val.is_a?(Array)
          (old_val + new_val).uniq
        else
          new_val
        end
      end
    end

    # This allows for customization of the attribute and parameter components.
    #
    # General customizations for all methods:
    #   automatic_components_for User,
    #     attributes: {remove: [:email, :time_zone]}, parameters: {add: {email: {type: :string, required: true, example: "fred@example.com"}}
    #   automatic_components_for User,
    #     attributes: {remove: [:email, :time_zone]}, parameters: {remove: [:email, :time_zone, :locale]}
    # Or specific customizations to parameters for create and update methods:
    #   automatic_components_for User,
    #     parameters: {update: {remove: [:email]}, create: {remove: [:time_zone]}},
    #     attributes: {remove: [:email, :time_zone]}
    def customize_component!(original, custom, method_type = nil)
      custom = custom.deep_stringify_keys.deep_transform_values { |v| v.is_a?(Symbol) ? v.to_s : v }

      # Check if customizations are provided for specific HTTP methods
      if custom.key?(method_type.to_s)
        custom = custom[method_type.to_s]
      end

      if custom.key?("add")
        custom["add"].each do |property, details|
          if details["required"]
            original["required"] << property
            details.delete("required")
          elsif details["required"] == false
            original["required"].delete(property)
            details.delete("required")
          end
          original["properties"][property] = details
          if details["example"]
            original["example"][property] = details["example"]
            details.delete("example")
          end
        end
      end

      if custom.key?("remove")
        Array(custom["remove"]).each do |property|
          original["required"].delete(property)
          original["properties"].delete(property)
          original["example"].delete(property)
        end
      end

      if custom.key?("only")
        original["properties"].keys.each do |property|
          unless Array(custom["only"]).include?(property)
            original["properties"].delete(property)
            original["required"].delete(property)
            original["example"].delete(property)
          end
        end
      end
    end
  end
end
