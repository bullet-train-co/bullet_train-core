require_relative "../../super_scaffold_base"
require "scaffolding/routes_file_manipulator"

module ActionModels
  class TargetsOneGenerator < Rails::Generators::Base
    include SuperScaffoldBase

    source_root File.expand_path("templates", __dir__)

    namespace "super_scaffold:action_models:targets_one"

    argument :action_model
    argument :target_model
    argument :parent_model

    class_option :skip_migration_generation, type: :boolean, default: false, desc: "Don't generate the model migration"
    class_option :skip_form, type: :boolean, default: false, desc: "Don't alter the new/edit form"
    class_option :skip_show, type: :boolean, default: false, desc: "Don't alter the show view"
    class_option :skip_table, type: :boolean, default: false, desc: "Only add to the new/edit form and show view."
    class_option :skip_locales, type: :boolean, default: false, desc: "Don't alter locale files"
    class_option :skip_api, type: :boolean, default: false, desc: "Don't alter the api payloads"
    class_option :skip_model, type: :boolean, default: false, desc: "Don't alter the model file"

    def generate
      if defined?(BulletTrain::ActionModels)
        # We add the name of the specific super_scaffolding command that we want to
        # invoke to the beginning of the argument string.
        ARGV.unshift "action-models:targets-one"
        BulletTrain::SuperScaffolding::Runner.new.run
      else
        puts "You must have Action Models installed if you want to use this generator.".red
        puts "Please refer to the documentation for more information: https://bullettrain.co/docs/action-models"
      end
    end
  end
end
