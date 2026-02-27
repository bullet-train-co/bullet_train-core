require_relative "lib/bullet_train/incoming_webhooks/version"

Gem::Specification.new do |spec|
  spec.name = "bullet_train-incoming_webhooks"
  spec.version = BulletTrain::IncomingWebhooks::VERSION
  spec.authors = ["Andrew Culver"]
  spec.email = ["andrew.culver@gmail.com"]
  spec.homepage = "https://github.com/bullet-train-co/bullet_train-core/tree/main/bullet_train-incoming_webhooks"
  spec.summary = "Bullet Train Incoming Webhooks"
  spec.description = spec.summary
  spec.license = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "test/controllers/webhooks/incoming/bullet_train_webhooks_controller_test.rb", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0.0"
  spec.add_dependency "bullet_train-super_scaffolding"
  spec.add_dependency "bullet_train-api"
  spec.add_dependency "bullet_train"

  spec.add_development_dependency "factory_bot_rails"
  spec.add_development_dependency "pg", "~> 1.3"
  spec.add_development_dependency "simplecov"
end
