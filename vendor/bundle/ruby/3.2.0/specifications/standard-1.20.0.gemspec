# -*- encoding: utf-8 -*-
# stub: standard 1.20.0 ruby lib

Gem::Specification.new do |s|
  s.name = "standard".freeze
  s.version = "1.20.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Justin Searls".freeze]
  s.bindir = "exe".freeze
  s.date = "2022-12-20"
  s.email = ["searls@gmail.com".freeze]
  s.executables = ["standardrb".freeze]
  s.files = ["exe/standardrb".freeze]
  s.homepage = "https://github.com/testdouble/standard".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 2.6.0".freeze)
  s.rubygems_version = "3.4.10".freeze
  s.summary = "Ruby Style Guide, with linter & automatic code fixer".freeze

  s.installed_by_version = "3.4.10" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rubocop>.freeze, ["= 1.40.0"])
  s.add_runtime_dependency(%q<rubocop-performance>.freeze, ["= 1.15.1"])
  s.add_runtime_dependency(%q<language_server-protocol>.freeze, ["~> 3.17.0.2"])
end
