module BulletTrain
  module SuperScaffolding
    module Scaffolders
      class JoinModelScaffolder < Scaffolder
        def run
          unless argv.count >= 3
            puts ""
            puts "🚅  usage: bin/super-scaffold join-model <JoinModel> <left_association> <right_association>"
            puts ""
            puts "E.g. Add project-specific tags to a project:"
            puts ""
            puts "  Given the following example models:".blue
            puts ""
            puts "    rails g model Project team:references name:string description:text"
            puts "    bin/super-scaffold crud Project Team name:text_field description:trix_editor"
            puts ""
            puts "    rails g model Projects::Tag team:references name:string"
            puts "    bin/super-scaffold crud Projects::Tag Team name:text_field"
            puts ""
            puts "  1️⃣  Use the standard Rails model generator to generate the join model:".blue
            puts ""
            puts "    rails g model Projects::AppliedTag project:references tag:references"
            puts ""
            puts "    👋 Don't run migrations yet! Sometimes Super Scaffolding updates them for you.".yellow
            puts ""
            puts "  2️⃣  Use `join-model` scaffolding to prepare the join model for use in `crud-field` scaffolding:".blue
            puts ""
            puts "    bin/super-scaffold join-model Projects::AppliedTag project_id{class_name=Project} tag_id{class_name=Projects::Tag}"
            puts ""
            puts "  3️⃣  Now you can use `crud-field` scaffolding to actually add the field to the form of the parent model:".blue
            puts ""
            puts "    bin/super-scaffold crud-field Project tag_ids:super_select{class_name=Projects::Tag}"
            puts ""
            puts "    👋 Heads up! There will be one follow-up step output by this command that you need to take action on."
            puts ""
            puts "  4️⃣  Now you can run your migrations.".blue
            exit
          end

          child = argv[0]
          primary_parent = argv[1].split("class_name=").last.split(",").first.split("}").first
          secondary_parent = argv[2].split("class_name=").last.split(",").first.split("}").first

          # There should only be two attributes.
          attributes = [argv[1], argv[2]]

          unless @options["skip-migration-generation"]
            attributes_without_options = attributes.map { |attribute| attribute.gsub(/{.*}$/, "") }
            attributes_without_id = attributes_without_options.map { |attribute| attribute.gsub(/_id$/, "") }
            attributes_with_references = attributes_without_id.map { |attribute| attribute + ":references" }

            generation_command = "bin/rails generate model #{child} #{attributes_with_references.join(" ")}"
            puts "Generating model with '#{generation_command}'".green
            `#{generation_command}`
          end

          # Pretend we're doing a `super_select` scaffolding because it will do the correct thing.
          attributes = attributes.map { |attribute| attribute.gsub("{", ":super_select{") }
          attributes = attributes.map { |attribute| attribute.gsub("}", ",required}") }

          transformer = Scaffolding::Transformer.new(child, [primary_parent], @options)

          # We need this transformer to reflect on the class names _just_ between e.g. `Project` and `Projects::Tag`, without the join model.
          has_many_through_transformer = Scaffolding::Transformer.new(secondary_parent, [primary_parent], @options)

          # We need this transformer to reflect on the association between `Projects::Tag` and `Projects::AppliedTag` backwards.
          inverse_transformer = Scaffolding::Transformer.new(child, [secondary_parent], @options)

          # We need this transformer to reflect on the class names _just_ between e.g. `Projects::Tag` and `Project`, without the join model.
          inverse_has_many_through_transformer = Scaffolding::Transformer.new(primary_parent, [secondary_parent], @options)

          # However, for the first attribute, we actually don't need the scope validator (and can't really implement it).
          attributes[0] = attributes[0].gsub("}", ",unscoped}")

          has_many_through_association = has_many_through_transformer.transform_string("completely_concrete_tangible_things")
          source = transformer.transform_string("absolutely_abstract_creative_concept.valid_$HAS_MANY_THROUGH_ASSOCIATION")
          source.gsub!("$HAS_MANY_THROUGH_ASSOCIATION", has_many_through_association)

          # For the second one, we don't want users to have to define the list of valid options in the join model, so we do this:
          attributes[1] = attributes[1].gsub("}", ",source=#{source}}")

          # This model hasn't been crud scaffolded, so a bunch of views are skipped here, but that's OK!
          # It does what we need on the files that exist.
          transformer.add_scaffolding_hooks_to_model

          transformer.suppress_could_not_find = true
          transformer.add_attributes_to_various_views(attributes, type: :crud_field)
          transformer.suppress_could_not_find = false

          # Add the `has_many ... through:` association in both directions.
          transformer.add_has_many_through_associations(has_many_through_transformer)
          inverse_transformer.add_has_many_through_associations(inverse_has_many_through_transformer)

          additional_steps = (transformer.additional_steps + has_many_through_transformer.additional_steps + inverse_transformer.additional_steps + inverse_has_many_through_transformer.additional_steps).uniq

          additional_steps.each_with_index do |additional_step, index|
            color, message = additional_step
            puts ""
            puts "#{index + 1}. #{message}".send(color)
          end
          puts ""
        end
      end
    end
  end
end
