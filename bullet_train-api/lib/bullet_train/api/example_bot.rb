module FactoryBot
  module ExampleBot
    attr_accessor :tables_to_reset

    def example(model, **options)
      factory = "#{model}_example"
      @tables_to_reset = [model.to_s.pluralize]

      object = nil

      ActiveRecord::Base.transaction do
        instance = FactoryBot.create(factory, **options)
        object = deep_clone(instance)

        raise ActiveRecord::Rollback
      end

      reset_tables!
      object
    end

    def example_list(model, quantity, **options)
      factory = "#{model}_example"
      @tables_to_reset = [model.to_s.pluralize]

      objects = []

      ActiveRecord::Base.transaction do
        instances = FactoryBot.create_list(factory, quantity, **options)

        instances.each do |instance|
          objects << deep_clone(instance)
        end

        raise ActiveRecord::Rollback
      end

      reset_tables!
      objects
    end

    private

    def reset_tables!
      @tables_to_reset.each do |name|
        ActiveRecord::Base.connection.reset_pk_sequence!(name)
      end
    end

    def deep_clone(instance)
      clone = instance.clone

      instance.class.reflections.each do |name, reflection|
        if reflection.macro == :has_many
          associations = instance.send(name).map { |association| association.clone }
          clone.send("#{name}=", associations)
          @tables_to_reset << name
        elsif reflection.macro == :belongs_to
          clone.send("#{name}=", instance.send(name).clone)
          @tables_to_reset << name.pluralize
        end
      end

      clone
    end
  end

  extend ExampleBot
end
