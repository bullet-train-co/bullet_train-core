# Bullet Train Roles

Bullet Train Roles provides a Yaml-based configuration layer on top of [CanCanCan](https://github.com/CanCanCommunity/cancancan). You can use this configuration file to simplify the definition of many common permissions, while still implementing more complicated permissions in CanCanCan's traditional `app/model/ability.rb`.

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

Add these lines to your application's Gemfile:

```ruby
gem "active_hash", github: "bullet-train-co/active_hash"
gem "bullet_train-roles"
```

> We have to link to a specific downstream version of ActiveHash temporarily while working to merge certain fixes and updates upstream.

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


## Usage

The provided `Role` model is backed by a Yaml configuration in `config/models/roles.yml`.

To help explain this configuration and its options, we'll provide the following hypothetical example:

```yaml
default:
  models:
    Project: read
    Billing::Subscription: read

editor:
  manageable_roles:
    - editor
  models:
    Project: crud

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
  - `crud` is a special value that we substitute for the 4 CRUD actions - create, read, update and destroy.
  This is instead of `manage` which covers all actions - 4 CRUD actions _and_ any extra actions the controller may respond to

The following things are true given the example configuration above:

 - By default, users on a team are read-only participants.
 - Users with the `editor` role:
   - can give other users the `editor` role.
   - can perform crud actions on project (create, read, update and destroy).
   - cannot perform any custom controller actions the projects controller responds to
 - Users with the `billing` role:
   - can give other users the `billing` role.
   - can create and update billing subscriptions.
 - Users with the `admin` role:
   - inherit all the privileges of the `editor` and `billing` roles.
   - can give other users the `editor`, `billing`, or `admin` role. (The ability to grant `editor` and `billing` privileges is inherited from the other roles listed in `includes`.)

### Assigning Multiple Actions per Resource

You can also grant more granular permissions by supplying a list of the specific actions per resource, like so:

```yaml
editor:
  models:
    project:
      - read
      - update
```

## Applying Configuration

All of these definitions are interpreted and translated into CanCanCan directives when we invoke the following Bullet Train helper in `app/models/ability.rb`:

```ruby
permit user, through: :memberships, parent: :team
```

In the example above:

 - `through` should reference a collection on `User` where access to a resource is granted. The most common example is the `memberships` association, which grants a `User` access to a `Team`. **In the context of `permit` discussions, we refer to the `Membership` model in this example as "the grant model".**
 - `parent` should indicate which level the models in `through` will grant a user access at. In the case of a `Membership`, this is `team`.

## Additional Grant Models

To illustrate the flexibility of this approach, consider that you may want to grant non-administrative team members different permissions for different `Project` objects on a `Team`. In that case, `permit` actually allows us to re-use the same role definitions to assign permissions that are scoped by a specific resource, like this:

```ruby
permit user, through: :projects_collaborators, parent: :project
```

In this example, `permit` is smart enough to only apply the permissions granted by a `Projects::Collaborator` record at the level of the `Project` it belongs to. You can turn any model into a grant model by adding `include Roles::Support` and adding a `role_ids:jsonb` attribute. You can look at `Scaffolding::AbsolutelyAbstract::CreativeConcepts::Collaborator` for an example.


## Restricting Available Roles

In some situations, you don't want all roles to be available to all Grant Models.  For example, you might have a `project_editor` role that only makes sense when applied at the Project level.  Note that this is only necessary if you want your project_editor to have more limited permissions than an admin user.  If a `project_editor` has full control of their project, you should probably just use the `admin` role.

By default all Grant Models will show all roles as options.  If you want to limit the roles available to a model, use the `roles_only` class method:

```ruby
class Membership < ApplicationRecord
  include Roles::Support
  roles_only :admin, :editor, :reader # Add this line to restrict the Membership model to only these roles
end
```

To access the array of all roles available for a particular model, use the `assignable_roles` class method.  For example, in your Membership form, you probably _only_ want to show the assignable_roles as options.  Your view could look like this:

```erb
<% Membership.assignable_roles.each do |role| %>
  <% if role.manageable_by?(current_membership.roles) %>
    <!-- View component for showing a role option. Probably a checkbox -->
  <% end %>
<% end %>
```

## Checking user permissions

Generally the CanCanCan helper method (`account_load_and_authorize_resource`) at the top of each controller will handle checking user permissions and will only load resources appropriate for the current user.

However, you may also want to check if a user can perform a specific action.  For example, in a view you may want to only show the edit button if the current user has permissions to edit the object.  For this, you can use regular CanCanCan helpers.  For example:

```
<%= link_to "Edit", [:account, @document] if can? :edit, @document %>
```

Sometimes, you might want to check for the presence of a specific role. We provide a helper to check for the admin role:
```
@membership.admin?
```

For all other roles, you can check for their presence like this:

```
@membership.roles.include?(Role.find("developer"))
```

However, when you do that, you're only checking the roles that have been directly assigned to that membership.

Imagine a scenario like this:
```
# roles.yml
admin:
  includes:
    - editor
    - billing

# somewhere else in your app:
@membership.roles << Role.admin
@membership.roles.include?(Role.find("editor"))
=> false
```

While that's technically correct that the user doesn't have the editor role, we probably want that to return true if we're checking what the user can and can't do.  For this situation, we really want to check if the user can perform a role rather than if they've had that role assigned to them.

```
# roles.yml

admin:
  includes:
    - editor
    - billing

# somewhere else in your app:

@membership.roles << Role.admin
@membership.roles.can_perform_role?(Role.find("editor"))
=> true

# You can also pass the role key as a symbol for a more concise syntax
@membership.roles.can_perform_role?(:editor)
=> true
```


## Debugging

If you want to see what CanCanCan directives are being created by your permit calls, you can add the `debug: true` option to your `permit` statement in `app/models/ability.rb`.

Likewise, to see what abilities are being added for a certain user, you can run the following on the Rails console:

```ruby
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
