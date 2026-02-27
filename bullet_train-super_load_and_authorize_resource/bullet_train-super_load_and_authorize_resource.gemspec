require_relative "lib/bullet_train/super_load_and_authorize_resource/version"

Gem::Specification.new do |spec|
  spec.name = "bullet_train-super_load_and_authorize_resource"
  spec.version = BulletTrain::SuperLoadAndAuthorizeResource::VERSION
  spec.authors = ["Andrew Culver"]
  spec.email = ["andrew.culver@gmail.com"]
  spec.homepage = "https://github.com/bullet-train-co/bullet_train-core/tree/main/bullet_train-super_load_and_authorize_resource"
  spec.summary = "Bullet Train Super Load And Authorize Resource"
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

  spec.add_dependency "cancancan"
  spec.add_dependency "rails", ">= 7.0.0"

  spec.add_development_dependency "pry"
  spec.add_development_dependency "simplecov"
end
