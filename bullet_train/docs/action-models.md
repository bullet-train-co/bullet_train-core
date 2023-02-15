# Action Models

Action Models make it easy to scaffold and implement user-facing custom actions in your Bullet Train application and API in a RESTful way. Action Models are perfect for situations where you want one or more of the following:

 - Bulk actions for a model where users can select one or more objects as targets.
 - Long-running background tasks where you want to keep users updated on their progress in the UI or notify them after completion.
 - Actions that have one or more configuration options available.
 - Tasks that can be configured now but scheduled to take place later.
 - Actions where you want to keep an in-app record of when it happened and who initiated the action.
 - Tasks that one team member can initiate, but a team member with elevated privileges has to approve.

Examples of real-world features that can be easily implemented using Action Models include:

 - A project manager can archive multiple projects at once.
 - A customer service agent can refund multiple payments at once and provide a reason.
 - A user can see progress updates while their 100,000 row CSV file is imported.
 - A marketing manager can publish a blog post now or schedule it for publication tomorrow at 9 AM.
 - A contributor can propose a content template change that will be applied after review and approval.

Importantly, Action Models aren't a special new layer in your application or a special section of your code base. Instead, they're just regular models, with corresponding scaffolded views and controllers, that exist alongside the rest of your domain model. They leverage Bullet Train's existing strengths around domain modeling and code generation with Super Scaffolding.

They're also super simple and very DRY. Consider the following example, assuming the process of archiving each project is very complicated and takes a lot of time:

```ruby
class Projects::ArchiveAction < ApplicationRecord
  include Actions::TargetsMany
  include Actions::ProcessesAsync
  include Actions::HasProgress
  include Actions::CleansUp

  belongs_to :team

  def valid_targets
    team.projects
  end

  def perform_on_target(project)
    project.archive
  end
end
```

## Installation

### 1. Purchase Bullet Train Pro

First, [purchase Bullet Train Pro](https://buy.stripe.com/aEU7vc4dBfHtfO89AV). Once you've completed this process, you'll be issued a private token for the Bullet Train Pro package server. The process is currently completed manually, so you may have to wait a little to receive your keys.

### 2. Install the Package

Then you can specify the Ruby gem in your `Gemfile`:

```ruby
source "https://YOUR_TOKEN_HERE@gem.fury.io/bullettrain" do
  gem "bullet_train-action_models"
end
```

Don't forget to run `bundle install` and `rails restart`.

## Super Scaffolding Commands

You can get detailed information about using Super Scaffolding to generate different types of Action Models like so:

```
bin/super-scaffold action-model:targets-many
bin/super-scaffold action-model:targets-one
bin/super-scaffold action-model:targets-one-parent
```

## Basic Example

### 1. Generate and scaffold an example `Project` model.

```
rails g model Project team:references name:string
bin/super-scaffold crud Project Team name:text_field
```

### 2. Generate and scaffold an archive action for projects.

```
bin/super-scaffold action-model:targets-many Archive Project Team
```

### 3. Implement the action logic.

Open `app/models/projects/archive_action.rb` and update the implementation of this method:

```ruby
def perform_on_target(project)
  project.archive
end
```

You're done!

## Additional Examples

### Add configuration options to an action.

Because Action Models are just regular models, you can add new fields to them with Super Scaffolding the same as any other model. This is an incredible strength, because it means the configuration options for your Action Models can leverage the entire suite of form field types available in Bullet Train, and maintaining the presentation of those options to users is like maintaining any other model form in your application.

For example:

```
rails g migration add_notify_users_to_projects_archive_actions notify_users:boolean
# side quest: update the generated migration with `default: false` on the new boolean field.
bin/super-scaffold crud-field Projects::ArchiveAction notify_users:boolean
```

Now users will be prompted with that option when they perform this action, and you can update your logic to take action based on it, or at least pass on the information to another method that takes action based on it:

```ruby
def perform_on_target(project)
  project.archive(send_notification: notify_users)
end
```

## Action Types

Action Models can be generated in three flavors:

 - `action-model:targets-many`
 - `action-model:targets-one`
 - `action-model:targets-one-parent`

### Targets Many

Action Models that _can_ target many objects are by far the most common, but it's important to understand that they're not only presented to users as bulk actions. Instead, by default, they're presented to users as an action available for each individual object, but they're also presented as a bulk action when users have selected multiple objects.

"Targets many" actions live at the same level in the domain model (and belong to the same parent) as the model they target. (If this doesn't make immediate sense, just consider that it would be impossible for instances of these actions to live under multiple targets at the same time.)

### Targets One

Sometimes you have an action that will only ever target one object at a time. In this case, they're generated a little differently and live under (and belong to) the model they target.

When deciding between "targets many" and "targets one", our recommendation is that you only use "targets one" for actions that you know for certain could never make sense targeting more than one object at the same time. For example, if you're creating a send action for an email that includes configuration options and scheduling details, you may be reasonably confident that you never need users to be able to schedule two different emails at the same time with the same settings. That would be a good candidate for a "targets one" action.

### Targets One Parent

This final type of action is available for things like importers that don't necessarily target specific existing objects by ID, but instead create many new or affect many existing objects under a specific parent based on the configuration of the action (like an attached CSV file.) These objects don't "target many" per se, but they live at the same level (and belong to the same parent) as the models they end up creating or affecting.

## Frequently Asked Questions

### Do Action Models have to be persisted to the database?

No. Action Models extend from `ApplicationRecord` by default, but if you're not using features that depend on persistence to the database, you can make them `include ActiveModel::API` instead. That said, it's probably not worth the trouble. As an alternative, consider just including `Actions::CleansUp` in your action to ensure it removes itself from the database after completion.
