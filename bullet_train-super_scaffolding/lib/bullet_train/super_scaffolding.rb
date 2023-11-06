require "bullet_train/super_scaffolding/version"
require "bullet_train/super_scaffolding/engine"
require "bullet_train/super_scaffolding/exceptions"
require "bullet_train/super_scaffolding/scaffolder"
require "bullet_train/super_scaffolding/scaffolders/crud_scaffolder"
require "bullet_train/super_scaffolding/scaffolders/crud_field_scaffolder"
require "bullet_train/super_scaffolding/scaffolders/join_model_scaffolder"
require "bullet_train/super_scaffolding/scaffolders/oauth_provider_scaffolder"

require "indefinite_article"
require "colorizer"

module BulletTrain
  module SuperScaffolding
    mattr_accessor :template_paths, default: []
    mattr_accessor :scaffolders, default: {
      "crud" => "BulletTrain::SuperScaffolding::Scaffolders::CrudScaffolder",
      "crud-field" => "BulletTrain::SuperScaffolding::Scaffolders::CrudFieldScaffolder",
      "join-model" => "BulletTrain::SuperScaffolding::Scaffolders::JoinModelScaffolder",
      "oauth-provider" => "BulletTrain::SuperScaffolding::Scaffolders::OauthProviderScaffolder"
    }

    class Runner
      def run
        # If this scaffolder is being run, it means that the developer
        # did not specify which scaffolder they want to use.
        puts ""
        puts "🚅  usage: bin/super-scaffold [type] (... | --help)"
        puts ""
        puts "Supported types of scaffolding:"
        puts ""
        puts "  crud"
        puts "  crud-field"
        puts "  join-model"
        puts "  oauth-provider"
        puts "  breadcrumbs"
        puts ""
        puts "Try \`bin/super-scaffold [type]` for usage examples.".blue
        puts ""

        # Make `rake` invocation compatible with how this was run historically.
        require "scaffolding/script"
      end
    end
  end
end
