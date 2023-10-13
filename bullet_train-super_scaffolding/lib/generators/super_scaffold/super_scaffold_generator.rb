class SuperScaffoldGenerator < Rails::Generators::Base
  source_root File.expand_path("templates", __dir__)

  # ##############################
  #
  # TODO: Should we retain some of these class options?
  #
  # By default we inherit a bunch of options that _would_ automatically be used if we
  # were writing a normal Rails generator that used normal methods of generating files.
  # So if you invoke this generator without passing any arguments (and without these
  # remove_class_option lines) then at the top of the help text you'd see info about all
  # of these options:
  #
  # ##############################
  #
  # rails g super_scaffold
  #
  # Options:
  #   [--skip-namespace], [--no-skip-namespace]              # Skip namespace (affects only isolated engines)
  #   [--skip-collision-check], [--no-skip-collision-check]  # Skip collision check
  #
  # Runtime options:
  #   -f, [--force]                    # Overwrite files that already exist
  #   -p, [--pretend], [--no-pretend]  # Run but do not make any changes
  #   -q, [--quiet], [--no-quiet]      # Suppress status output
  #   -s, [--skip], [--no-skip]        # Skip files that already exist
  #
  # ##############################
  #
  # Maye we have comparable options for some of these and should retain them and
  # pass them through to the rake task?

  remove_class_option :skip_namespace
  remove_class_option :skip_collision_check
  remove_class_option :force
  remove_class_option :pretend
  remove_class_option :quiet
  remove_class_option :skip

  namespace "super_scaffold"

  argument :model, type: :string
  argument :parent_models, type: :string
  argument :attributes, type: :array, default: [],  banner: "attribute:type attribute:type"

  class_option :skip_migration_generation, type: :boolean, default: false

  def generate
    # We add the name of the specific super_scaffolding command that we want to
    # invoke to the beginning of the argument string.
    ARGV.unshift "crud"
    BulletTrain::SuperScaffolding::Runner.new.run
  end
end
