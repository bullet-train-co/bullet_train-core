require_relative "lib/bullet_train/sortable/version"

Gem::Specification.new do |spec|
  spec.name = "bullet_train-sortable"
  spec.version = BulletTrain::Sortable::VERSION
  spec.authors = ["Andrew Culver"]
  spec.email = ["andrew.culver@gmail.com"]
  spec.homepage = "https://github.com/bullet-train-co/bullet_train-core/tree/main/bullet_train-sortable"
  spec.summary = "Bullet Train Sortable"
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
  spec.add_development_dependency "simplecov"

  spec.add_dependency "rails", ">= 6.0.0"
  # TODO: Ideally we'd be able to declare this dependency and have everything work in the starter repo.
  # For some reason I seem to need this to be declared in the starter repo for the JS file to be made available.
  spec.add_dependency "requestjs-rails"
end
