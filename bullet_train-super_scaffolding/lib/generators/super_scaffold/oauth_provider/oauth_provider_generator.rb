require_relative "../super_scaffold_base"

class OauthProviderGenerator < Rails::Generators::Base
  include SuperScaffoldBase

  source_root File.expand_path("templates", __dir__)

  namespace "super_scaffold:oauth_provider"

  argument :omniauth_gem
  argument :gems_provider_name
  argument :our_provider_name
  argument :PROVIDER_API_KEY_ENV_VAR_NAME
  argument :PROVIDER_API_SECRET_ENV_VAR_NAME

  class_option :icon, type: :string, desc: "Specify an icon."

  def generate
    # We add the name of the specific super_scaffolding command that we want to
    # invoke to the beginning of the argument string.
    ARGV.unshift "oauth-provider"
    BulletTrain::SuperScaffolding::Runner.new.run
  end
end
