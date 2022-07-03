# Action Models

Action Models make it easy to scaffold and implement user-facing custom actions in your Bullet Train application (and API) in a RESTful way. Action Models are perfect for situations where you want one or more of the following:

 - Bulk actions for a model where users can select one or more objects as targets.
 - Long-running background tasks where you want to keep users updated on their progress in the UI or notify then after completion.
 - Actions that have one or more configuration options available.
 - Tasks that can be configured now but scheduled to take place later.
 - Actions where you want to keep an in-app record of when it happened and who initiated the action.
 - Tasks that one team member can initiate, but a team member with elevated privileges has to approve.

Importantly, Action Models aren't a special new layer in your application or a special section of your code base. Instead, they're just regular models (with corresponding views and controllers) that exist alongside the rest of your domain model, leveraging Bullet Train's existing strengths around domain modeling and Super Scaffolding.

They're also super simple and very DRY. Consider the following example, assuming the process of archiving a project is very complicated and takes a lot of time:

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

## 1. Purchase Bullet Train Pro

First, [purchase Bullet Train Pro](#). Once you've completed this process, you'll be issued a private token for the Bullet Train Pro package server. The process is currently completed manually, so you may have to way a little to receive your keys.

## 2. Install the Package

You'll need to specify both Ruby gems in your `Gemfile`, since we have to specify a private source for both:

```
source "https://YOUR_TOKEN_HERE@gem.fury.io/bullettrain" do
  gem "bullet_train-action_models"
end
```

Don't forget to run `bundle install` and `rails restart`. 

## Super Scaffolding Commands

You can get detailed information about using Super Scaffolding to generate different types of action models like so:

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

```
def perform_on_target(project)
  project.archive
end
```

## Additional Examples

### Adding configuration options to an action.

Because Action Models are just regular models, you can add new fields to them with Super Scaffolding the same as any other model. For example:

```
rails g migration add notify_users_to_projects_archive_actions notify_users:boolean
bin/super-scaffold crud-field Projects::ArchiveAction notify_users:boolean
```

Now users will be prompted with that option when they perform this action, and you can update your logic to take action based on it, or at least pass on the information to another method that takes action based on it:

```
def perform_on_target(project)
  project.archive(send_notification: notify_users)
end
```
