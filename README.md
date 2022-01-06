# Bullet Train Roles

Bullet Train Roles provides a Yaml-based configuration layer on top of CanCanCan's ability file. You can use this configuration file to simplify the definition of many common permissions, while still implementing more complicated permissions in CanCanCan's traditional `app/model/ability.rb`. 

Additionally, Bullet Train Roles makes it trivial to assign the same roles and associated permissions at different levels in your application. For example, you can assign someone administrative privileges at a team level, or only at a project level.

Bullet Train Roles was created by [Andrew Culver](http://twitter.com/andrewculver) and [Adam Pallozzi](https://twitter.com/adampallozzi).

## Example Domain Model 

For the sake of this document, we're going to assume the following example modeling around users and teams:

- A `User` belongs to a `Team` via a `Membership`.
- A `User` only has one `Membership` per team.
- A `Membership` can have zero, one, or many `Role`s assigned.
- A `Membership` without a `Role` is just a default team member.

You don't have to name your models the same thing in order to use this Ruby Gem, but it does depend on having a similar structure. 

> If you're interested in reading more about how and why Bullet Train implements this structure, you can [read about it on our blog](https://blog.bullettrain.co/teams-should-be-an-mvp-feature/).

## Installation

Add this line to your application's Gemfile:

```ruby
gem "bullet_train-roles"
```

And then execute the following in your shell:

```
bundle install
```

Finally, run the installation generator:

```
rails generate bullet_train:roles:install
```

The installer defaults to installing a configuration for `Membership` and `Team`, but it will prompt you so you can specify different models if they differ in your application.

The installer will:

 - stub out a configuration file in `config/models/roles.yml`.
 - create a database migration to add `role_ids:jsonb` to `Membership`.
 - add `include Role::Support` to `app/models/membership.rb`.
 - add a basic `permit` call in `app/models/ability.rb`.


### Limitations

The generators currently assume you're using PostgreSQL and `jsonb` will be available when generating a `role_ids` column. If you're using MySQL, you can edit these migrations and use `json` instead, although you won't be able to set a default value and you'll need to take care of this in the model.

## Usage

The provided `Role` model is backed (via [ActiveHash](https://github.com/active-hash/active_hash)) by a Yaml configuration in `config/models/roles.yml`.

To help explain this configuration and it's options, we'll provide the following hypothetical example:

```
default:
  models:
    Project: read
    Billing::Subscription: read

editor:
  manageable_roles:
    - editor
  models:
    Project: manage

billing:
  manageable_roles:
    - billing
  models:
    Billing::Subscription: manage

admin:
  includes:
    - editor
    - billing
  manageable_roles:
    - admin
```

Here's a breakdown of the structure of the configuration file:

 - `default` represents all permissions that are granted to any active member on a team.
 - `editor`, `billing`, and `admin` represent additional roles that can be assigned to a membership.
 - `models` provides a list of resources that members with a specific role will be granted.
 - `manageable_roles` provides a list of roles that can be assigned to other users by members that have the role being defined.
 - `includes` provides a list of other roles whose permissions should also be made available to members with the role being defined.
 - `manage`, `read`, etc. are all CanCanCan-defined actions that can be granted.

The following things are true given the example configuration above:

 - By default, users on a team are read-only participants.
 - Users with the `editor` role:
   - can give other users the `editor` role.
   - can modify project details.
 - Users with the `billing` role:
   - can give other users the `billing` role.
   - can create and update billing subscriptions.
 - Users with the `admin` role:
   - inherit all the privileges of the `editor` and `billing` roles.
   - can give other users the `editor`, `billing`, or `admin` role. (The ability to grant `editor` and `billing` privileges is inherited from the other roles listed in `includes`.)

### Assigning Multiple Actions per Resource

You can also grant more granular permissions by supplying a list of the specific actions per resource, like so:

```
editor:
  models:
    project:
      - read
      - update
```

## Applying Configuration

All of these definitions are interpreted and translated into CanCanCan directives when we invoke the following Bullet Train helper in `app/models/ability.rb`:

```
permit user, through: :memberships, parent: :team
```

In the example above:

 - `through` should reference a collection on `User` where access to a resource is granted. The most common example is the `memberships` association, which grants a `User` access to a `Team`. **In the context of `permit` discussions, we refer to the `Membership` model in this example as "the grant model".**
 - `parent` should indicate which level the models in `through` will grant a user access at. In the case of a `Membership`, this is `team`.

## Additional Grant Models

To illustrate the flexibility of this approach, consider that you may want to grant non-administrative team members different permissions for different `Project` objects on a `Team`. In that case, `permit` actually allows us to re-use the same role definitions to assign permissions that are scoped by a specific resource, like this:

```
permit user, through: :projects_collaborators, parent: :project
```

In this example, `permit` is smart enough to only apply the permissions granted by a `Projects::Collaborator` record at the level of the `Project` it belongs to. You can turn any model into a grant model by adding `include Roles::Support` and adding a `role_ids:jsonb` attribute. You can look at `Scaffolding::AbsolutelyAbstract::CreativeConcepts::Collaborator` for an example.

## Debugging
If you want to see what CanCanCan directives are being created by your permit calls, you can add the `debug: true` option to your `permit` statement in `app/models/ability.rb`.

Likewise, to see what abilities are being added for a certain user, you can run the following on the Rails console:

```
user = User.first
Ability.new(user).permit user, through: :projects_collaborators, parent: :project, debug: true
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bullet-train-co/bullet_train-roles. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/bullet-train-co/bullet_train-roles/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the BulletTrain::Roles project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/bullet-train-co/bullet_train-roles/blob/main/CODE_OF_CONDUCT.md).
