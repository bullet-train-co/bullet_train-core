require_relative "lib/bullet_train/integrations/stripe/version"

Gem::Specification.new do |spec|
  spec.name = "bullet_train-integrations-stripe"
  spec.version = BulletTrain::Integrations::Stripe::VERSION
  spec.authors = ["Andrew Culver"]
  spec.email = ["andrew.culver@gmail.com"]
  spec.homepage = "https://github.com/bullet-train-co/bullet_train-core/tree/main/bullet_train-integrations-stripe"
  spec.summary = "Example Stripe platform integration for Bullet Train applications."
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

  spec.add_dependency "rails", ">= 7.0.0"
  spec.add_dependency "stripe"
  spec.add_dependency "omniauth", "~> 2.0"
  spec.add_dependency "omniauth-stripe-connect-v2"

  # TODO Remove when we're able to properly upgrade Omniauth.
  # https://github.com/omniauth/omniauth/wiki/Resolving-CVE-2015-9284
  spec.add_dependency "omniauth-rails_csrf_protection", "~> 1.0"

  spec.add_development_dependency "simplecov"
end
