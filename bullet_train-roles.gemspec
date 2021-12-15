# frozen_string_literal: true

require_relative "lib/bullet_train/roles/version"

Gem::Specification.new do |spec|
  spec.name          = "bullet_train-roles"
  spec.version       = BulletTrain::Roles::VERSION
  spec.authors       = ["Prabin Poudel", "Andrew Culver"]
  spec.email         = %w[probnpoudel@gmail.com andrew.culver@gmail.com]

  spec.summary       = "Yaml-backed ApplicationHash CanCan Roles"
  spec.description   = "Yaml-backed ApplicationHash CanCan Roles"
  spec.homepage      = "https://github.com/bullet-train-co/bullet_train-roles"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bullet-train-co/bullet_train-roles"
  spec.metadata["changelog_uri"] = "https://github.com/bullet-train-co/bullet_train-roles/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end

  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_development_dependency "cancancan", "~> 3.3.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "standard", "~> 1.5.0"

  spec.add_dependency "knapsack_pro", "~> 3.1.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
