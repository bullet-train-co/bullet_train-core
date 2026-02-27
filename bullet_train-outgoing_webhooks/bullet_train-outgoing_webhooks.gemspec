require_relative "lib/bullet_train/outgoing_webhooks/version"

Gem::Specification.new do |spec|
  spec.name = "bullet_train-outgoing_webhooks"
  spec.version = BulletTrain::OutgoingWebhooks::VERSION
  spec.authors = ["Andrew Culver"]
  spec.email = ["andrew.culver@gmail.com"]
  spec.homepage = "https://github.com/bullet-train-co/bullet_train-core/tree/main/bullet_train-outgoing_webhooks"
  spec.summary = "Allow users of your Rails application to subscribe and receive webhooks when activity takes place in your application."
  spec.description = spec.summary
  spec.license = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_development_dependency "standard"
  spec.add_development_dependency "pg", "~> 1.3"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "webmock"

  spec.add_dependency "rails", ">= 7.0.0"
  spec.add_dependency "public_suffix"
end
