require_relative "super_scaffold_base"

class SuperScaffoldGenerator < Rails::Generators::Base
  include SuperScaffoldBase

  source_root File.expand_path("templates", __dir__)

  namespace "super_scaffold"

  argument :model, type: :string
  argument :parent_models, type: :string
  argument :attributes, type: :array, default: [], banner: "attribute:type attribute:type"

  class_option :skip_migration_generation, type: :boolean, default: false, desc: "Don't generate the model migration"
  class_option :sortable, type: :boolean, default: false, desc: "https://bullettrain.co/docs/super-scaffolding/sortable"
  class_option :namespace, type: :string, desc: "https://bullettrain.co/docs/namespacing"
  class_option :sidebar, type: :string, desc: "Pass the Themify icon or Font Awesome icon to automatically add it to the navbar"
  class_option :only_index, type: :boolean, default: false, desc: "Only scaffold the index view for a model"
  class_option :skip_views, type: :boolean, default: false, desc: "Don't generate views"
  class_option :skip_form, type: :boolean, default: false, desc: "Don't generate a new/edit form"
  class_option :skip_locales, type: :boolean, default: false, desc: "Don't generate locale files"
  class_option :skip_api, type: :boolean, default: false, desc: "Don't generate api files"
  class_option :skip_model, type: :boolean, default: false, desc: "Don't generate a model file"
  class_option :skip_controller, type: :boolean, default: false, desc: "Don't generate a controller file"
  class_option :skip_routes, type: :boolean, default: false, desc: "Don't generate any routes"
  class_option :skip_parent, type: :boolean, default: false, desc: "Don't add child models to the show page of their parent"

  def generate
    # We add the name of the specific super_scaffolding command that we want to
    # invoke to the beginning of the argument string.
    ARGV.unshift "crud"
    BulletTrain::SuperScaffolding::Runner.new.run
  end
end
