# frozen_string_literal: true

require_relative "lib/bullet_train/internationalization/version"

Gem::Specification.new do |spec|
  spec.name = "bullet_train-internationalization"
  spec.version = BulletTrain::Internationalization::VERSION
  spec.authors = ["Andrew Culver", "Gabriel Zayas"]
  spec.email = ["andrew.culver@gmail.com", "g-zayas@hotmail.com"]
  spec.homepage = "https://github.com/bullet-train-co/bullet_train"
  spec.summary = "A gem for housing Bullet Train's standard localizations."
  spec.description = spec.summary
  spec.license = "MIT"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rails", "~> 7.0.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "standard", "~> 1.5.0"
end
