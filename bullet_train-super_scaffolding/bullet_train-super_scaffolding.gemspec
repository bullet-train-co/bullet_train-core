require_relative "lib/bullet_train/super_scaffolding/version"

Gem::Specification.new do |spec|
  spec.name = "bullet_train-super_scaffolding"
  spec.version = BulletTrain::SuperScaffolding::VERSION
  spec.authors = ["Andrew Culver"]
  spec.email = ["andrew.culver@gmail.com"]
  spec.homepage = "https://github.com/bullet-train-co/bullet_train-core/tree/main/bullet_train-super_scaffolding"
  spec.summary = "Bullet Train Super Scaffolding"
  spec.description = spec.summary
  spec.license = "MIT"

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

  spec.add_dependency "rails", ">= 7.0.0"
  spec.add_dependency "masamune-ast", "~> 2.0.2"
  spec.add_dependency "colorize"

  # For Super Scaffolding: "select *a* team member" vs. "select *an* option".
  spec.add_dependency "indefinite_article"
end
