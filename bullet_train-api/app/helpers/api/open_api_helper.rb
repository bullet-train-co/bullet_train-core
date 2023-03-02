module Api
  module OpenApiHelper
    def indent(string, count)
      lines = string.lines
      first_line = lines.shift
      lines = lines.map { |line| ("  " * count).to_s + line }
      lines.unshift(first_line).join.html_safe
    end

    # TODO: Remove this method? It's not being used anywhere
    def components_for(model)
      for_model model do
        indent(render("api/#{@version}/open_api/#{model.name.underscore.pluralize}/components"), 2)
      end
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
    module_function :gem_paths

    def automatic_paths_for(model, parent, except: [])
      output = render("api/#{@version}/open_api/shared/paths", except: except)
      output = Scaffolding::Transformer.new(model.name, [parent&.name]).transform_string(output).html_safe
      indent(output, 1)
    end

    def automatic_components_for(model, locals: {})
      path = "app/views/api/#{@version}"
      paths = ([path] + gem_paths.map { |gem_path| "#{gem_path}/#{path}" })

      jbuilder = Jbuilder::Schema.renderer(paths, locals: {
        # If we ever get to the point where we need a real model here, we should implement an example team in seeds that we can source it from.
        model.name.underscore.split("/").last.to_sym => model.new,
        # Same here, if we ever need this to be a real object, this should be `test@example.com` with an `SecureRandom.hex` password.
        :current_user => User.new
      }.merge(locals))

      main_object = FactoryBot.example(model.model_name.singular)

      schema_json = jbuilder.json(
        main_object || model.new,
        title: I18n.t("#{model.name.underscore.pluralize}.label"),
        # TODO Improve this. We don't have a generic description for models we can use here.
        description: I18n.t("#{model.name.underscore.pluralize}.label")
      )

      attributes_output = JSON.parse(schema_json)

      if has_strong_parameters?("Api::#{@version.upcase}::#{model.name.pluralize}Controller".constantize)
        strong_params_module = "Api::#{@version.upcase}::#{model.name.pluralize}Controller::StrongParameters".constantize
        strong_parameter_keys = BulletTrain::Api::StrongParametersReporter.new(model, strong_params_module).report
        if strong_parameter_keys.last.is_a?(Hash)
          strong_parameter_keys += strong_parameter_keys.pop.keys
        end

        parameters_output = JSON.parse(schema_json)
        parameters_output["required"]&.select! { |key| strong_parameter_keys.include?(key.to_sym) }
        parameters_output["properties"]&.select! { |key, value| strong_parameter_keys.include?(key.to_sym) }
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

    def attribute(attribute)
      heading = t("#{current_model.name.underscore.pluralize}.fields.#{attribute}.heading")
      attribute_data = current_model.columns_hash[attribute.to_s]

      # TODO: File fields don't show up in the columns_hash. How should we handle these?
      # Default to `string` when the type returns nil.
      type = attribute_data.nil? ? "string" : attribute_data.type

      attribute_block = <<~YAML
        #{attribute}:
          description: "#{heading}"
          type: #{type}
      YAML
      indent(attribute_block.chomp, 2)
    end
    alias_method :parameter, :attribute

    private

    def has_strong_parameters?(controller)
      methods = controller.action_methods
      methods.include?("create") || methods.include?("update")
    end
  end
end
