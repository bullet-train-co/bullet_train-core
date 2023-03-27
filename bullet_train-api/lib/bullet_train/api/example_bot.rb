require_relative "../../../app/helpers/api/open_api_helper"

module FactoryBot
  module ExampleBot
    attr_accessor :tables_to_reset

    def example(model, **options)
      @tables_to_reset = [model.to_s.pluralize]

      object = nil

      ActiveRecord::Base.transaction do
        instance = FactoryBot.create(factory(model), **options)
        object = deep_clone(instance)

        raise ActiveRecord::Rollback
      end

      reset_tables!
      object
    end

    def example_list(model, quantity, **options)
      @tables_to_reset = [model.to_s.pluralize]

      objects = []

      ActiveRecord::Base.transaction do
        instances = FactoryBot.create_list(factory(model), quantity, **options)

        instances.each do |instance|
          objects << deep_clone(instance)
        end

        raise ActiveRecord::Rollback
      end

      reset_tables!
      objects
    end

    %i[get_examples get_example post_examples post_parameters put_example put_parameters patch_example patch_parameters].each do |method|
      define_method(method) do |model, **options|
        _path_examples(method.to_s, model, **options)
      end
    end

    private

    def factory(model)
      factories = FactoryBot.factories.instance_variable_get(:@items).keys
      factories.include?("#{model}_example") ? "#{model}_example" : model
    end

    def reset_tables!
      @tables_to_reset.each do |name|
        ActiveRecord::Base.connection.reset_pk_sequence!(name) if ActiveRecord::Base.connection.table_exists?(name)
      end
    end

    def deep_clone(instance)
      clone = instance.clone

      instance.class.reflections.each do |name, reflection|
        if reflection.macro == :has_many
          associations = instance.send(name).map { |association| association.clone }
          clone.send("#{name}=", associations)
          @tables_to_reset << name
        elsif %i[belongs_to has_one].include?(reflection.macro)
          clone.send("#{name}=", instance.send(name).clone)
          @tables_to_reset << name.pluralize
        end
      end

      clone
    end

    include ::Api::OpenApiHelper
    def _path_examples(method, model, **options)
      version = options.delete(:version) || "v1"

      case method.split("_").first
      when "get"
        count = (options.delete(:count) || method == "get_examples") ? 2 : 1
        template, class_name, var_name, values = _set_values(method, model, count)
      else
        template, class_name, var_name, values = _set_values("get_example", model)

        unless %w[example examples].include?(method.split("_").last)
          if has_strong_parameters?("::Api::#{version.upcase}::#{class_name.pluralize}Controller".constantize)
            strong_params_module = "::Api::#{version.upcase}::#{class_name.pluralize}Controller::StrongParameters".constantize
            strong_parameter_keys = BulletTrain::Api::StrongParametersReporter.new(class_name.constantize, strong_params_module).report
            if strong_parameter_keys.last.is_a?(Hash)
              strong_parameter_keys += strong_parameter_keys.pop.keys
            end

            output = _json_output(template, version, class_name, var_name, values)

            parameters_output = JSON.parse(output)
            parameters_output&.select! { |key| strong_parameter_keys.include?(key.to_sym) }

            return indent(parameters_output.to_yaml.delete_prefix("---\n"), 6).html_safe
          end
          return nil
        end
      end

      _yaml_output(template, version, class_name, var_name, values)
    end

    def _set_values(method, model, count = 1)
      if count > 1
        values = FactoryBot.example_list(model, count)
        class_name = values.first.class.name
        var_name = class_name.demodulize.underscore.pluralize
      else
        values = FactoryBot.example(model)
        class_name = values.class.name
        var_name = class_name.demodulize.underscore
      end

      template = (method == "get_examples") ? "index" : "show"

      [template, class_name, var_name, values]
    end

    def _json_output(template, version, class_name, var_name, values)
      ActionController::Base.render(
        template: "api/#{version}/#{class_name.underscore.pluralize}/#{template}",
        assigns: {"#{var_name}": values},
        formats: :json
      )
    end

    def _yaml_output(template, version, class_name, var_name, values)
      indent(
        JSON.parse(
          _json_output(template, version, class_name, var_name, values)
        ).to_yaml
            .delete_prefix("---\n"), 7
      ).html_safe
    end
  end

  extend ExampleBot
end
