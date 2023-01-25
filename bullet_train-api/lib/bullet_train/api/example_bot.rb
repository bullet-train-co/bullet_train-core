module BulletTrain
  module Api
    module ExampleBot
      def example(model, **options)
        factory = "#{model}_example"
        tables_to_reset = [model.to_s.pluralize]
        object = nil

        ActiveRecord::Base.transaction do
          instance = FactoryBot.create(factory, **options)
          object = instance.clone

          instance.class.reflections.each do |name, reflection|
            if reflection.macro == :has_many
              associations = instance.send(name).map { |association| association.clone }
              object.send("#{name}=", associations)
              tables_to_reset << name
            elsif reflection.macro == :belongs_to
              object.send("#{name}=", instance.send(name).clone)
              tables_to_reset << name.pluralize
            end
          end

          raise ActiveRecord::Rollback
        end

        tables_to_reset.each do |name|
          ActiveRecord::Base.connection.reset_pk_sequence!(name)
        end

        object
      end

      def example_list(model, quantity, **options)

      end
    end

    extend ExampleBot
  end
end
