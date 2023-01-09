require "factory_bot"
require "active_support/inflector/methods"

module BulletTrain
  module Api
    module ExampleBot
      FactoryBot.definition_file_paths << "app/views/api/v1/open_api/examples"

      SUFFIX = "-bullet_train-api-example"

      def define(&block)
        DSL.run(block)
      end

      def example(model, **options)
        object = FactoryBot.build("#{model}#{SUFFIX}", **options)
        object.id ||= 1
        object.created_at = Time.now if object.respond_to?(:created_at?)
        object.updated_at = Time.now if object.respond_to?(:updated_at?)
        object
      end

      class DSL
        def example(name, **options, &block)
          options[:class] ||= name.to_s.pluralize.classify
          name = "#{name}#{BulletTrain::Api::ExampleBot::SUFFIX}"

          FactoryBot.define { factory(name, **options, &block) }
        end

        def self.run(block)
          new.instance_eval(&block)
        end
      end
    end

    extend ExampleBot
  end
end

module FactoryBot
  class DefinitionProxy
    def example(name, options = {}, &block)
      name = "#{name}#{BulletTrain::Api::ExampleBot::SUFFIX}"
      @child_factories << [name, options, block]
    end
  end

  class Declaration

    class Association < Declaration
      def initialize(name, *options)
        super(name, false)
        @options = options.dup
        @overrides = options.extract_options!
        @overrides[:example] = "#{@overrides[:example]}#{BulletTrain::Api::ExampleBot::SUFFIX}" if @overrides[:example]
        @factory_name = @overrides.delete(:example) || @overrides.delete(:factory) || name
        @traits = options
      end
    end
  end
end
