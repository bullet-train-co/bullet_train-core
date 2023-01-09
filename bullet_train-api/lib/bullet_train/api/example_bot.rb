require "factory_bot"
require "active_support/inflector/methods"

# This file contains code allowing creating OpenAPI examples using FactoryBot,
# with almost the same DSL, and avoiding declaring same factories as already
# being defined in tests/factories.
#
# Main differences are:
# - `BulletTrain::Api` class instead of `FactoryBot`
# - `example` definition keyword instead of `factory`
# - `example` method instead of `create`
#
# Example:
#   BulletTrain::Api.define do
#     example :team do
#       name 'Awesome Team'
#     end
#
#     example :user do
#       association :current_team, example: :team
#     end
#   end
#
#   > post = BulletTrain::Api.example(:post)
#   > #<Team...>
#   >
#   > post.author
#   > #<User...>
module BulletTrain
  module Api
    module ExampleBot
      # This is the folder where OpenAPI examples are supposed to be stored
      FactoryBot.definition_file_paths << "app/views/api/v1/open_api/examples"

      # Suffix added to FactoryBot factory names to separate them from factories used in tests
      # It should never be seen for the end user
      SUFFIX = "-bullet_train-api-example"

      # Replaces FactoryBot's `define` method.
      #
      # Example:
      #   BulletTrain::Api.define do
      #     ...
      #   end
      def define(&block)
        DSL.run(block)
      end

      # Replaces FactoryBot's `create` or `build` methods.
      #
      # Example:
      #   BulletTrain::Api.example(:user)
      def example(model, **options)
        object = FactoryBot.build("#{model}#{SUFFIX}", **options)
        object.id ||= 1
        object.created_at = Time.now if object.respond_to?(:created_at?)
        object.updated_at = Time.now if object.respond_to?(:updated_at?)
        object
      end

      class DSL
        # Replaces FactoryBot's `factory` method.
        #
        # Example:
        #   example :user do
        #     name 'Joey'
        #   end
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
    # Allows nested examples.
    #
    # Example:
    #   example :user do
    #     name 'Joey'
    #
    #     example :invited_user do
    #       invited true
    #     end
    #   end
    def example(name, options = {}, &block)
      name = "#{name}#{BulletTrain::Api::ExampleBot::SUFFIX}"
      @child_factories << [name, options, block]
    end
  end

  class Declaration
    # Allows using BulletTrain::Api.example instead of FactoryBot.factory when declaring associations.
    #
    # Example:
    #   example :team do
    #     name 'Awesome Team'
    #   end
    #
    #   example :user do
    #     association :current_team, example: :team # Always use the exactly this construction
    #   end
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
