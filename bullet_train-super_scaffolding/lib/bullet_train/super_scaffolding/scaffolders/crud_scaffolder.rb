module BulletTrain
  module SuperScaffolding
    module Scaffolders
      class CrudScaffolder < Scaffolder
        def run
          unless argv.count >= 3
            puts ""
            puts "🚅  usage: bin/super-scaffold crud <Model> <ParentModel[s]> <attribute:type> <attribute:type> ..."
            puts ""
            puts "E.g. a Team has many Sites with some attributes:"
            puts "  rails g model Site team:references name:string url:text"
            puts "  bin/super-scaffold crud Site Team name:text_field url:text_area"
            puts ""
            puts "E.g. a Section belongs to a Page, which belongs to a Site, which belongs to a Team:"
            puts "  rails g model Section page:references title:string body:text"
            puts "  bin/super-scaffold crud Section Page,Site,Team title:text_field body:text_area"
            puts ""
            puts "E.g. an Image belongs to either a Page or a Site:"
            puts "  Doable! See https://bit.ly/2NvO8El for a step by step guide."
            puts ""
            puts "E.g. Pages belong to a Site and are sortable via drag-and-drop:"
            puts "  rails g model Page site:references name:string path:text"
            puts "  bin/super-scaffold crud Page Site,Team name:text_field path:text_area --sortable"
            puts ""
            puts "🏆 Protip: Commit your other changes before running Super Scaffolding so it's easy to undo if you (or we) make any mistakes."
            puts "If you do that, you can reset to your last commit state by using `git checkout .` and `git clean -d -f` ."
            puts ""
            puts "Give it a shot! Let us know if you have any trouble with it! ✌️"
            puts ""
            exit
          end

          child = argv[0]
          parents = argv[1] ? argv[1].split(",") : []
          parents = parents.map(&:classify).uniq
          parent = parents.first
          child_parts = child.split("::")
          parent_parts = parent.split("::")

          # Pop off however many spaces match.
          child_parts_dup = child_parts.dup
          parent_parts_dup = parent_parts.dup
          parent_without_namespace = nil
          child_parts_dup.each.with_index do |child_part, idx|
            if child_part == parent_parts_dup[idx]
              child_parts.shift
              parent_parts.shift
            else
              parent_without_namespace = parent_parts.join("::")
              break
            end
          end

          # get all the attributes.
          attributes = argv[2..]

          check_required_options_for_attributes("crud", attributes, child, parent)

          # `tr` here compensates for namespaced models (i.e. - `Projects::Deliverable` to `projects/deliverable`).
          parent_reference = parent_without_namespace.tableize.singularize.tr("/", "_")
          tableized_child = child.tableize.tr("/", "_")

          # Pull the parent foreign key from the `create_table` call
          # if a migration with `add_reference` hasn't been created.
          migration_file_name = `grep "add_reference :#{tableized_child}, :#{parent_reference}" db/migrate/*`.split(":").shift
          migration_file_name ||= `grep "create_table :#{tableized_child}" db/migrate/*`.split(":").shift
          parent_t_references = "t.references :#{parent_reference}"
          parent_add_reference = "add_reference :#{tableized_child}, :#{parent_reference}"
          parent_foreign_key = nil
          File.open(migration_file_name).readlines.each do |line|
            parent_foreign_key = line.match?(/#{parent_add_reference}|#{parent_t_references}/)
            break if parent_foreign_key
          end

          unless parent_foreign_key
            puts "#{child} does not have a foreign key referencing #{parent}".red
            puts ""
            puts "Please re-generate your model, or execute the following to add the foreign key:"
            puts "rails generate migration add_#{parent_reference}_to_#{tableized_child} #{parent_reference}:references\n"
            exit 1
          end

          unless parents.include?("Team")
            raise "Parents for #{child} should trace back to the Team model, but Team wasn't provided. Please confirm that all of the parents tracing back to the Team model are present and try again.\n" \
              "E.g.:\n" \
              "rails g model Section page:references title:text body:text\n" \
              "bin/super-scaffold crud Section Page,Site,Team title:text body:text\n"
          end

          transformer = Scaffolding::Transformer.new(child, parents, @options)
          transformer.scaffold_crud(attributes)

          transformer.additional_steps.each_with_index do |additional_step, index|
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
