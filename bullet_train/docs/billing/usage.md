# Bullet Train Usage Limits

Bullet Train provides a holistic method for defining model-based usage limits in your Rails application.

## Installation

### 1. Purchase Bullet Train Pro

First, [purchase Bullet Train Pro](https://buy.stripe.com/aEU7vc4dBfHtfO89AV). Once you've completed this process, you'll be issued a private token for the Bullet Train Pro package server. The process is currently completed manually, so you may have to way a little to receive your keys.

### 2. Install the Package

### 2.1. Add the Private Ruby Gems

You'll need to specify both Ruby gems in your `Gemfile`, since we have to specify a private source for both:

```ruby
source "https://YOUR_TOKEN_HERE@gem.fury.io/bullettrain" do
  gem "bullet_train-billing"
  gem "bullet_train-billing-stripe" # Or whichever billing provider you're using.
  gem "bullet_train-billing-usage"
end
```

### 2.2. Bundle Install

```
bundle install
```

### 2.3. Copy Database Migrations

Use the following two commands on your shell to copy the required migrations into your local project:

```
cp `bundle show --paths | grep bullet_train-billing | sort | head -n 1`/db/migrate/* db/migrate
cp `bundle show --paths | grep bullet_train-billing-stripe | sort | head -n 1`/db/migrate/* db/migrate
```

Note this is different than how many Rails engines ask you to install migrations. This is intentional, as we want to maintain the original timestamps associated with these migrations.

### 2.4. Run Migrations

```
rake db:migrate
```

### 2.5. Add Model Support

There are two concerns that need to be added to your application models.

The first concern is `Billing::UsageSupport` and it allows tracking of usage of verbs on the models you want to support tracking usage on. It is recommended to add this capability to all models, so you can add this.

```
# app/models/application_record.rb

class ApplicationRecord
  include Billing::Usage
end
```

The second concern is `Billing::HasTrackers` and it allows any model to hold the usage tracking. This is usually done on the `Team` model.

```
# app/models/team.rb

class Team
  include Billing::HasTrackers
end
```

## Configuration
Usage limit configuration piggybacks on your [product definitions](/docs/billing/stripe.md) in `config/models/billing/products.yml`. It may help to make reference to the [default product definitions in the Bullet Train starter repository](https://github.com/bullet-train-co/bullet_train/blob/main/config/models/billing/products.yml).

## Basic Usage Limits
All limit definitions are organized by product, then by model, and finally by _verb_. For example, you can define the number of projects a team is allowed to have on a basic plan like so:

```yaml
basic:
  prices:
    # ...
  limits:
    projects:
      have:
        count: 3
        enforcement: hard
        upgradable: true
```

Any verb that your model supports can be used. It is recommended to standardize on using the action as the verb. For example, when creating a new model, use the verb _create_. When deleting a model, use the verb _delete_, and so on.

It's important to note that `have` is a special verb and represents the simple `count` of a given model on a `Team`. All _other_ verbs will be interpreted as [time-based usage limits](#time-based-usage-limits).

### Options
 - `enforcement` can be `hard` or `soft`.
   - When a `hard` limit is hit, the create form will be disabled.
   - When a `soft` limit is hit, users are simply notified, but can continue to surpass the limit.
 - `upgradable` indicates whether or not a user should be prompted to upgrade when they hit this limit.

### Excluding Records from `have` Usage Limits
All models have an overridable `billable` scope that includes all records by default. You can override this scope on any given model to ensure that certain records are filtered out from consideration when calculating usage limits. For example, we do the following on `Membership` to exclude removed team members from contributing to any limitation put on the number of team members, like so:

```ruby
scope :billable, -> { current_and_invited }
```

Another example may be excluding "archived" items within the billable usage count such as:

```ruby
module Archivable
  extend ActiveSupport::Concern

  included do
    scope :billable, -> { where(archived_at: nil) }

    # ...
  end
end
```

## Time-Based Usage Limits

### Configuring Limits
In addition to simple `have` usage limits, you can specify other types of usage limits by defining other verbs. For example, you can limit the number of blog posts that can be published in a 3-day period on the free plan like this:

```yaml
free:
  limits:
    blogs/posts:
      publish:
        count: 1
        duration: 3
        interval: days
        enforcement: hard
```

 - `count` is how many times something can happen.
 - `duration` and `interval` represent the time period we'll track for, e.g. "3 days" in this case.
 - Valid options for `interval` are anything you can append to an integer, e.g. `minutes`, `hours`, `days`, `weeks`, `months`, etc., both plural and singular.

### Tracking Usage
For these custom verbs, it's important to also instrument the application for tracking when these actions have taken place. For example:

```ruby
class Blogs::Post < ApplicationRecord
  # ...

  def publish!
    update(published_at: Time.zone.now)
    track_billing_usage(:published)
  end
end
```

It is important that you use the past tense of the verb when tracking so it is tracked appropriately. If you'd like to increment the usage count by more than one, you can pass a quantity like `count: 5` to this call.

### Cycling Trackers Regularly
We include a Rake task you'll need to run on a regular basis in order to cycle the usage trackers that are created at a `Team` level. By default, you should probably run this every five minutes:

```
rake billing:cycle_usage_trackers
```

## Checking Usage Limits

### Checking Time-Based Limits
To make decisions based on or enforce time-based `hard` limits in your views and controllers, you can use the `current_limits` helper like this:

```ruby
current_limits.can?(:publish, Blogs::Post)
```

(You can also pass quantities like `count: 5` as an option.)

### Checking Basic Limits
For basic `have` limits, forms generated by Super Scaffolding will be automatically disabled when a `hard` limit has been hit. Index views will also alert users to a limit being hit or broken for both `hard` and `soft` limits.

> If your Bullet Train application scaffolding predates this feature, you can reference the newest Tangible Things [index template](https://github.com/bullet-train-co/bullet_train-super_scaffolding/blob/main/app/views/account/scaffolding/completely_concrete/tangible_things/_index.html.erb) and [form template](https://github.com/bullet-train-co/bullet_train-super_scaffolding/blob/main/app/views/account/scaffolding/completely_concrete/tangible_things/_form.html.erb) to see how we're using the `shared/limits/index` and `shared/limits/form` partials to present and enforce usage limits, and copy this usage in your own views.

To make decisions in other views or within controllers, you can use the `#exhausted?` method on the `current_limits` helper to check if any basic `have` limits have been hit or exceeded.

```ruby
# Inspects broken hard limits by default
current_limits.exhausted?(Blogs::Post)

# Or you can specify the `enforcement` level
current_limits.exhausted?(Blogs::Post, :soft)
```

#### Presenting an Error

If you want to present an error or warning to the user based on their usage, there themed alert partials that can be displayed in your views. These partials can be rendered via the path `shared/limits/error` and `shared/limits/warning` respectively.

```ruby
<%= render "shared/limits/warning", model: model.class %>

<%= render "shared/limits/error", action: :create, model: model.class, count: 1, cancel_path: cancel_path %>
```

These partials have various local assigns that are used to configure the partial.

* `action` - the `verb` to check the usage on the model for. Defaults to `have`.
* `color` - the `color` value to use for the alert partial. Defaults to `red` for errors and `yellow` for warnings.
* `count` - the number of objects intended to be acted upon. Defaults to 1.
* `model` - the `class` relationship as the model to inspect usage on. Defaults to `form.object.class`.

### Changing Products
The default list of products that the limits are based off of are the products available from your Billing products, which is most likely a list of subscription plans from Stripe.

You can change this default behavior by creating your own billing limiter and overriding the `current_products` method. This method should return a list of products that all respond to a `limits` message. The rest of the behavior is encapsulated in the `Billing::Limiter::Base` concern.

```ruby
# app/models/billing/email_limiter.rb

class Billing::EmailLimiter
  include Billing::Limiter::Base

  def current_products
    products = Billing::Product.data

    EmailService.retrieve_product_tiers.map do |tier|
      add_product_limit(tier, products)
    end
  end
end
```
