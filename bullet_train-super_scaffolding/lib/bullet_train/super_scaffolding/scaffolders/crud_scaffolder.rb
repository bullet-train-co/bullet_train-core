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

          migration_file_name = `grep "create_table :#{child.tableize}" db/migrate/*`.split(":").shift
          parent_foreign_key = nil
          File.open(migration_file_name).readlines.each do |line|
            parent_foreign_key = line.match?("t.references :#{parent.tableize.singularize}")
            break if parent_foreign_key
          end

          unless parent_foreign_key
            raise "#{child} does not have a foreign key referencing #{parent}.\n" \
                  "Make sure you generate your model with a references type:\n" \
                  "rails generate model Project team:references ...\n" \
                  "\n"
          end

          unless parents.include?("Team")
            raise "Parents for #{child} should trace back to the Team model, but Team wasn't provided. Please confirm that all of the parents tracing back to the Team model are present and try again.\n" \
              "E.g.:\n" \
              "rails g model Section page:references title:text body:text\n" \
              "bin/super-scaffold crud Section Page,Site,Team title:text body:text\n"
          end

          # get all the attributes.
          attributes = argv[2..]

          check_required_options_for_attributes("crud", attributes, child, parent)

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
