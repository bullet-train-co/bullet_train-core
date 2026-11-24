require_relative "lib/bullet_train/routes/version"

Gem::Specification.new do |spec|
  spec.name = "bullet_train-routes"
  spec.version = BulletTrain::Routes::VERSION
  spec.authors = ["Andrew Culver"]
  spec.email = ["andrew.culver@gmail.com"]
  spec.homepage = "https://github.com/bullet-train-co/bullet_train-core/tree/main/bullet_train-routes"
  spec.summary = "Bullet Train Routes"
  spec.description = "Black magic for defining model-driven routes."
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_development_dependency "standard"
  spec.add_development_dependency "simplecov"

  spec.add_dependency "rails", ">= 7.0.0"
end
