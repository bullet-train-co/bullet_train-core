# frozen_string_literal: true

require_relative "lib/bullet_train//roles/version"

Gem::Specification.new do |spec|
  spec.name = "bullet_train-roles"
  spec.version = Roles::VERSION
  spec.authors = ["Prabin Poudel", "Andrew Culver"]
  spec.email = %w[andrew.culver@gmail.com]

  spec.summary = "Yaml-backed ApplicationHash for CanCan Roles"
  spec.description = "Yaml-backed ApplicationHash for CanCan Roles"
  spec.homepage = "https://github.com/bullet-train-co/bullet_train-core/tree/main/bullet_train-roles"
  spec.license = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bullet-train-co/bullet_train-roles"
  spec.metadata["changelog_uri"] = "https://github.com/bullet-train-co/bullet_train-roles/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end

  spec.require_paths = ["lib"]

  spec.add_development_dependency "byebug", "~> 11.1.0"
  spec.add_development_dependency "factory_bot_rails", "~> 6.2.0"
  spec.add_development_dependency "knapsack_pro", "~> 3.1.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "pg", "~> 1.3"
  spec.add_development_dependency "rails", "~> 7.0.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "standard", "~> 1.5.0"

  spec.add_runtime_dependency "active_hash"
  spec.add_runtime_dependency "activesupport"
  spec.add_runtime_dependency "cancancan"
  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
