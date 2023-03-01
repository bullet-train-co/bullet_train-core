require_relative "lib/bullet_train/version"

Gem::Specification.new do |spec|
  spec.name = "bullet_train"
  spec.version = BulletTrain::VERSION
  spec.authors = ["Andrew Culver"]
  spec.email = ["andrew.culver@gmail.com"]
  spec.homepage = "https://github.com/bullet-train-co/bullet_train"
  spec.summary = "Bullet Train"
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

  spec.post_install_message = <<-MESSAGE
    If you're upgrading `bullet_train-*` Ruby gems and you run into any new
    issues, you should probably also pull in updates from the Bullet Train
    starter repository into your local application, just to make sure
    everything is synced up. See https://bullettrain.co/docs/upgrades for
    details.
  MESSAGE

  spec.add_development_dependency "standard"

  spec.add_dependency "rails", ">= 6.0.0"
  spec.add_dependency "bullet_train-fields"
  spec.add_dependency "bullet_train-roles"
  spec.add_dependency "bullet_train-super_load_and_authorize_resource"
  spec.add_dependency "bullet_train-has_uuid"
  spec.add_dependency "bullet_train-scope_validator"
  spec.add_dependency "bullet_train-themes"
  spec.add_dependency "bullet_train-routes"
  spec.add_dependency "devise"
  spec.add_dependency "xxhash"

  # This has been broken since Rails 7.
  # spec.add_dependency "devise-two-factor"
  # spec.add_dependency "rqrcode"

  spec.add_dependency "cancancan"

  # We use this to add "'s" as appropriate in certain headings.
  spec.add_dependency "possessive"

  # We've standardized on Sidekiq for background job processing.
  spec.add_dependency "sidekiq"

  # We use this to detect the size of the logo assets.
  spec.add_dependency "fastimage"

  # We don't want to develop in a world where we can't `ap` our objects for a clean presentation of them.
  spec.add_dependency "awesome_print"

  # Add helpful scopes automatically on booleans and date/time attributes.
  spec.add_dependency "microscope"

  # Serving language based on browser settings.
  spec.add_dependency "http_accept_language"

  # Reactive view magic.
  # The `updates_for` feature replaces Bullet Train's earlier "Cable Collections" feature.
  spec.add_dependency "cable_ready", "5.0.0.pre9"
  spec.add_dependency "hiredis"

  # Add named slots to regular Rails partials.
  spec.add_dependency "nice_partials", "~> 0.1"

  # Allow users to document and showcase their partials, components, view helpers, etc.
  spec.add_dependency "showcase-rails"

  # Inline all CSS for emails.
  spec.add_dependency "premailer-rails"

  # Define ENV values in `config/application.yml`.
  spec.add_dependency "figaro"

  # Validate email addresses.
  spec.add_dependency "valid_email"

  # Allow users to supply content with markdown formatting. Powers our markdown() view helper.
  spec.add_dependency "commonmarker" # TODO ➡️ `bullet_train-docs`?

  # Extract the body from emails received using action inbox.
  spec.add_dependency "extended_email_reply_parser" # TODO ➡️ `bullet_train-conversations`

  # Conversations.
  spec.add_runtime_dependency "unicode-emoji"

  # Pagination.
  spec.add_runtime_dependency "pagy"

  # We don't want to develop in a world where we don't have `binding.pry` or `object.pry` for debugging.
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-stack_explorer"

  # Password strength.
  spec.add_dependency "devise-pwned_password"
end
