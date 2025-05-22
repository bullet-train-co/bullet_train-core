require_relative "lib/bullet_train/api/version"

Gem::Specification.new do |spec|
  spec.name = "bullet_train-api"
  spec.version = BulletTrain::Api::VERSION
  spec.authors = ["Andrew Culver"]
  spec.email = ["andrew.culver@gmail.com"]
  spec.homepage = "https://github.com/bullet-train-co/bullet_train-core/tree/main/bullet_train-api"
  spec.summary = "Bullet Train API"
  spec.description = "API capabilities for apps built with Bullet Train framework"
  spec.license = "MIT"

  # TODO: Remove some time after 1.6.27
  spec.post_install_message = "
    Bullet Train is switching to separate translations for API documentation.
    To automatically update existing translations, run once:

    bundle exec rake bullet_train:api:create_translations

  "

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib,docs}/**/*", "MIT-LICENSE", "Rakefile", "README.md", ".bt-link"]
  end

  spec.add_development_dependency "standard"
  spec.add_development_dependency "simplecov"

  #spec.add_dependency "bullet_train-super_scaffolding"
  spec.add_dependency "bullet_train"

  spec.add_dependency "rails", ">= 6.0.0"
  spec.add_dependency "pagy", "~> 8"
  spec.add_dependency "pagy_cursor"
  spec.add_dependency "doorkeeper"
  spec.add_dependency "jbuilder-schema", "~> 2.6.6"
  spec.add_dependency "factory_bot"
end
