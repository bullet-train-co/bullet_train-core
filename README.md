# Bullet Train Roles

This Ruby Gem provides a Yaml-based configuration layer on top of CanCanCan's ability file. You can use this configuration file to simplify the definition of the most common types of permissions, while still implementing more complicated permissions in CanCanCan's traditional `app/model/ability.rb`.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "bullet_train-roles"
```

And then execute the following in your shell:

```
bundle install
```

## Usage

To get started, run:

```
rails generate bullet_train:roles:install User Membership Team
```

In this example:

 - `User` is the model that represents a signed-in user account.
 - `Membership` is the model that grants a `User` access to a group organization.
 - `Team` is the model that represents a group organization.

This will:

 - create a basic configuration in `config/models/roles.yml`
 - create a database migration to add `role_ids` to `Membership`
 - add `include Role::Support` to `app/models/membership.rb`
 - add a call to `permit` in `app/models/ability.rb`

## Limitations

 - The generators currently assume you're using PostgreSQL and `jsonb` will be available when generating a `role_ids` column. If you're using MySQL, you can edit these migrations and use `json` instead, although you won't be able to set a default value and you'll need to take care of this in the model.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bullet-train-co/bullet_train-roles. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/bullet-train-co/bullet_train-roles/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the BulletTrain::Roles project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/bullet-train-co/bullet_train-roles/blob/main/CODE_OF_CONDUCT.md).
