require_relative "lib/bullet_train/themes/light/version"

Gem::Specification.new do |spec|
  spec.name = "bullet_train-themes-light"
  spec.version = BulletTrain::Themes::Light::VERSION
  spec.authors = ["Andrew Culver"]
  spec.email = ["andrew.culver@gmail.com"]
  spec.homepage = "https://github.com/bullet-train-co/bullet_train-themes-light"
  spec.summary = "Bullet Train Themes: Light"
  spec.description = "Bullet Train Themes: Light"
  spec.license = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md", "tailwind.light.config.js", ".bt-link"]
  end

  spec.add_development_dependency "standard"

  spec.add_dependency "rails", ">= 6.0.0"
  spec.add_dependency "bullet_train-themes-tailwind_css"
end
