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
      # create_attributes_output = attributes_output
      # update_attributes_output = attributes_output

      # Allow customization of Attributes
      customize_component!(attributes_output, options[:attributes], "create", model.name.underscore) if options[:attributes]
      # method_type = "create"
      # create_attributes_custom = options[:attributes]["create"] if options[:attributes].is_a?(Hash) && options[:attributes].key?("create")
      # create_attributes_custom ||= options[:attributes]
      # customize_component!(create_attributes_output, create_attributes_custom, "create", model.name.underscore) if create_attributes_custom

      # update_attributes_custom = options[:attributes]["update"] if options[:attributes].is_a?(Hash) && options[:attributes].key?("update")
      # update_attributes_custom ||= options[:attributes]
      # customize_component!(update_attributes_output, update_attributes_custom, "update") if update_attributes_custom

      # attributes_custom = create_attributes_output

      # Add "Attributes" part to $ref's
      update_ref_values!(attributes_output)
      # update_ref_values!(create_attributes_output, "create")
      # update_ref_values!(update_attributes_output, "update")

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
        strong_params_module_name = "Api::#{@version.upcase}::#{model.name.pluralize}Controller::StrongParameters".constantize
        strong_params_module = BulletTrain::Api::StrongParametersReporter.new(model, strong_params_module_name)

        create_parameters_output = process_strong_parameters(strong_params_module, schema_json, "create", **options)
        update_parameters_output = process_strong_parameters(strong_params_module, schema_json, "update", **options)

        # puts "CREATE PARAMETERS OUTPUT: #{create_parameters_output}"
        # puts "UPDATE PARAMETERS OUTPUT: #{update_parameters_output}"

        (
          indent(attributes_output.to_yaml.gsub("---", "#{model.name.gsub("::", "")}Attributes:"), 3) +
            # indent("    " + create_attributes_output.to_yaml.gsub("---", "#{model.name.gsub("::", "")}AttributesCreate:"), 3) +
            # indent("    " + update_attributes_output.to_yaml.gsub("---", "#{model.name.gsub("::", "")}AttributesUpdate:"), 3) +
            indent("    " + create_parameters_output.to_yaml.gsub("---", "#{model.name.gsub("::", "")}ParametersCreate:"), 3) +
            indent("    " + update_parameters_output.to_yaml.gsub("---", "#{model.name.gsub("::", "")}ParametersUpdate:"), 3)
        ).html_safe
      else

        indent(attributes_output.to_yaml.gsub("---", "#{model.name.gsub("::", "")}Attributes:"), 3)
          .html_safe
      end
    end

    def process_strong_parameters(strong_params_module, schema_json, method_type, **options)
      strong_parameter_keys = strong_params_module.report(method_type)
      strong_parameter_keys += strong_parameter_keys.pop.keys if strong_parameter_keys.last.is_a?(Hash)

      parameters_output = JSON.parse(schema_json)
      parameters_output["required"].select! { |key| strong_parameter_keys.include?(key.to_sym) }
      parameters_output["properties"].select! { |key| strong_parameter_keys.include?(key.to_sym) }

      # HERE'S WHERE IT"S WRONG FOR THE COMPONENTS - it needs the 'wrapper' key and to strip it for the right request type
      # parameters_output["example"]&.select! { |key, value| strong_parameter_keys.include?(key.to_sym) && value.present? }
      parameters_output["example"]&.select! { |key, value| strong_parameter_keys.include?(key.to_sym) }

      # tmp fix for the examples wrapper: - but it also needs to do the same for the params added via the customize_component method
      # if parameters_output["example"]
      #   parameters_output["example"] = { strong_params_module.model_name.underscore => parameters_output["example"] }
      # else
      #   parameters_output["example"] = { strong_params_module.model_name.underscore => {} }
      # end

      # BUT WHY IS IT WRONG FOR THE post_examples in the _path replacement

      # Allow customization of Parameters
      # customize_component!(parameters_output, options[:parameters], strong_params_module.model_name.underscore) if options[:parameters]

      parameters_custom = options[:parameters][method_type] if options[:parameters].is_a?(Hash) && options[:parameters].key?(method_type)
      parameters_custom ||= options[:parameters]
      puts "XXXXXXXXXX"
      puts "module = #{strong_params_module.model_name.underscore}"
      puts "method_type: #{method_type}"
      puts "parameters_custom: #{parameters_custom}"
      # puts "XXXXX"
      # puts "parameters_output: #{parameters_output}"
      # puts "~~~~~~"
      # puts "parameters_custom: #{parameters_custom}"
      customize_component!(parameters_output, parameters_custom, method_type, strong_params_module.model_name.underscore) if parameters_custom
      # puts "parameters_output: #{parameters_output}"
      # puts "~~~~~~"

      # if parameters_output["example"]
      #   parameters_output["example"] = { strong_params_module.model_name.underscore.split("/").last => parameters_output["example"] }
      # else
      #   parameters_output["example"] = { strong_params_module.model_name.underscore.split("/").last => {} }
      # end

      parameters_output
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

    def has_strong_parameters?(controller)
      methods = controller.action_methods
      methods.include?("create") || methods.include?("update")
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

    # This method allows customization of the attributes and parameters components.
    # e.g. automatic_components_for Team, attributes: {add: {password: {type: :string, description: "Test", required: true, example: "password-ABC"}}, remove: :time_zone}, parameters: {add: {password: {type: :string, description: "Test", required: true, example: "password-ABC"}}, remove: :time_zone}
    #  automatic_components_for User, attributes: {remove: [:email, :time_zone]}, parameters: {remove: [:email, :time_zone, :locale]}
    #  automatic_components_for Membership, attributes: {remove: :team_id}, parameters: {remove: :user_first_name}
    #  automatic_components_for Webhooks::Outgoing::Endpoint, attributes: {only: [:id, :team_id]}, parameters: {only: :url}
    # def customize_component!(original, custom)
    #   custom = custom.deep_stringify_keys.deep_transform_values { |v| v.is_a?(Symbol) ? v.to_s : v }

    #   automatic_components_for User,
    #     create: {attributes: {remove: [:email, :time_zone]}, parameters: {remove: [:email, :time_zone, :locale]}},
    #     update: {attributes: {add: {password: {type: :string, description: "Test", required: true, example: "password-ABC"}}, remove: :time_zone}}
    # or
      # automatic_components_for User, attributes: {remove: [:email, :time_zone]}, parameters: {remove: [:email, :time_zone, :locale]}


      # Specific customizations for create and update methods:
      # automatic_components_for User,
      #   create: {attributes: {remove: [:email, :time_zone]}, parameters: {remove: [:email, :time_zone, :locale]}},
      #   update: {attributes: {add: {password: {type: :string, description: "Test", required: true, example: "password-ABC"}}, remove: :time_zone}}

      # General customizations for both methods:
      # automatic_components_for User,
      #   attributes: {remove: [:email, :time_zone]}, parameters: {remove: [:email, :time_zone, :locale]}
      # automatic_components_for User,
      #   attributes: {remove: [:email, :time_zone]}, parameters: {remove: [:email, :time_zone, :locale]}


    def customize_component!(original, custom, method_type, class_name)
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
          end
          original["properties"][property] = details
          if details["example"]
            original["example"][property] = details["example"]
            details.delete("example")
          end
          # original["properties"][property] = details
          # if details["example"]
          #   original["example"] ||= {}
          #   original["example"][class_name] ||= {}
          #   original["example"][class_name][property] = details["example"]
          #   details.delete("example")
          # end
        end
      end

      if custom.key?("remove")
        Array(custom["remove"]).each do |property|
          original["required"].delete(property)
          original["properties"].delete(property)
          original["example"].delete(property)
          # original.dig("example", class_name)&.delete(property)
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
