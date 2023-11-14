require_relative './super_scaffold_base'

class IncomingWebhooksGenerator < Rails::Generators::Base
  include SuperScaffoldBase

  source_root File.expand_path("templates", __dir__)

  namespace "super_scaffold:incoming_webhooks"

  argument :provider_name

  def generate
    # We add the name of the specific super_scaffolding command that we want to
    # invoke to the beginning of the argument string.
    ARGV.unshift "incoming-webhooks"
    BulletTrain::SuperScaffolding::Runner.new.run
  end
end
