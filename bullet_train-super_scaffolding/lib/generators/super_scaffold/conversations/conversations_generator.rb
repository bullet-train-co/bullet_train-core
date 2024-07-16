require_relative "../super_scaffold_base"
require "scaffolding/routes_file_manipulator"

class ConversationsGenerator < Rails::Generators::Base
  include SuperScaffoldBase

  source_root File.expand_path("templates", __dir__)

  namespace "super_scaffold:conversations"

  argument :target_model
  argument :parent_model

  def generate
    if defined?(BulletTrain::Conversations)
      # We add the name of the specific super_scaffolding command that we want to
      # invoke to the beginning of the argument string.
      ARGV.unshift "conversations"
      BulletTrain::SuperScaffolding::Runner.new.run
    else
      puts "You must have Conversations installed if you want to use this generator.".red
      puts "Please refer to the documentation for more information: https://bullettrain.co/docs/conversations"
    end
  end
end
