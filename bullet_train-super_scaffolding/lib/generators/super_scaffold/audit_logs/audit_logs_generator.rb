require_relative "../super_scaffold_base"
require "scaffolding/routes_file_manipulator"

class AuditLogsGenerator < Rails::Generators::Base
  include SuperScaffoldBase

  source_root File.expand_path("templates", __dir__)

  namespace "super_scaffold:audit_logs"

  argument :target_model, type: :string
  argument :parent_model, type: :string
  argument :attributes, type: :array, banner: "attribute:type attribute:type"

  def generate
    if defined?(BulletTrain::AuditLogs)
      # We add the name of the specific super_scaffolding command that we want to
      # invoke to the beginning of the argument string.
      ARGV.unshift "audit-logs"
      BulletTrain::SuperScaffolding::Runner.new.run
    else
      puts "You must have AuditLogs installed if you want to use this generator.".red
      puts "Please refer to the documentation for more information: https://bullettrain.co/docs/audit-logs"
    end
  end
end
