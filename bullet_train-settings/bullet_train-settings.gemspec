require_relative "lib/settings/version"

Gem::Specification.new do |spec|
  spec.name = "bullet_train-settings"
  spec.version = BulletTrain::Settings::VERSION
  spec.authors = ["Andrew Culver", "Yuri Sidorov"]
  spec.email = ["andrew.culver@gmail.com", "git@yurisidorov.com"]
  spec.homepage = "https://github.com/bullet-train-co/bullet_train-settings"
  spec.summary = "Bullet Train Settings"
  spec.description = spec.summary
  spec.license = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end
end
