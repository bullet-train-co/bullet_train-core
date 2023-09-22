module BulletTrain
  module SuperScaffolding
    module Scaffolders
      class CrudFieldScaffolder < Scaffolder
        def run
          unless argv.count >= 2
            puts ""
            puts "🚅  usage: bin/super-scaffold crud-field <Model> <attribute:type> <attribute:type> ... [options]"
            puts ""
            puts "E.g. add a description and body to Pages:"
            puts "  rails g migration add_description_etc_to_pages description:text body:text"
            puts "  bin/super-scaffold crud-field Page description:text_area body:text_area"
            puts ""
            puts "Options:"
            puts ""
            puts "  --skip-table: Only add to the new/edit form and show view."
            puts ""
            exit
          end

          # We pass this value to parents to create a new Scaffolding::Transformer because
          # we don't actually need knowledge of the parent to add the new field.
          parents = [""]
          child = argv[0]

          # get all the attributes.
          attributes = argv[1..]

          check_required_options_for_attributes("crud-field", attributes, child)

          transformer = Scaffolding::Transformer.new(child, parents, @options)
          transformer.add_attributes_to_various_views(attributes, type: :crud_field)

          transformer.additional_steps.uniq.each_with_index do |additional_step, index|
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
