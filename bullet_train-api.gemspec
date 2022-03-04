require_relative "lib/bullet_train/api/version"

Gem::Specification.new do |spec|
  spec.name = "bullet_train-api"
  spec.version = BulletTrain::Api::VERSION
  spec.authors = ["Andrew Culver"]
  spec.email = ["andrew.culver@gmail.com"]
  spec.homepage = "https://github.com/bullet-train-co/bullet_train-api"
  spec.summary = "Bullet Train API"
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
  spec.add_dependency "grape", "~> 1.6.0"
  spec.add_dependency "grape-cancan"
  spec.add_dependency "grape-jsonapi"
  spec.add_dependency "grape-swagger"
  spec.add_dependency "grape_on_rails_routes"
  # We can't do this until there is an updated release.
  # spec.add_dependency "wine_bouncer"
  spec.add_dependency "kaminari"
  spec.add_dependency "api-pagination"
  spec.add_dependency "rack-cors"
  spec.add_dependency "jsonapi-serializer"
  spec.add_dependency "doorkeeper"
end
