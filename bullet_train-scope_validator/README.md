# Bullet Train Scope Validator

Bullet Train Scope Validator provides a simple pattern for protecting `belongs_to` associations from malicious ID stuffing. It was created by [Andrew Culver](https://twitter.com/andrewculver) and extracted from [Bullet Train](https://bullettrain.co).

## Illustrating the Problem

By default in a multitenant Rails application, unless special care is given to validating the ID assigned to a `belongs_to` association, malicious users can stuff arbitrary IDs into their request and cause an application to bleed data from other tenants.

Consider the following example from a customer relationship management (CRM) system that two competitive companies use:

### Example Models

```ruby
class Team < ApplicationRecord
  has_many :customers
  has_many :deals
end

class Customer < ApplicationRecord
  belongs_to :team
end

class Deal < ApplicationRecord
  belongs_to :team
  belongs_to :customer
end
```

### Example Controller

```ruby
class DealsController < ApplicationController
  # 👋 Not illustrated: this controller loads `@team` safely, and has a `new` and `show` action.

  def create
    if @team.deals.create(deal_params)
      redirect_to @deal
    else
      render :new
    end
  end

  def deal_params
    params.require(:deal).permit(:customer_id)
  end
end
```

☝️ Note that Strong Parameters allows `customer_id` to be set by incoming requests and isn't responsible for validating the value. We also wouldn't _want_ Strong Parameters to be responible for this, since we'd end up with duplicate validation logic in our API controllers and other places. This is a responsibility of the model.

### Example Form

```erb
<%= form.collection_select(:customer_id, @team.customers, :id, :name) %>
```

☝️ Note that the `@team.customers.all` is properly scoped to only show customers from the current team.

### Example Show View

```
We have a deal with <%= @deal.customer.name %>!
```

### The "Exploit"

A malicious user can:

 - Begin adding a new deal to their account.
 - Inspect the DOM and replace the `<select>` element for `customer_id` with an `<input type="text">` element.
 - Set the value to any number, particularly numbers that are IDs they know don't belong to their account.
 - Submit the form to create the deal.
 - When the deal is shown, it will say "We have a deal with Nintendo!", where "Nintendo" is actually the customer of another team in the system. ☠️ We've bled customer data across our application's tenant boundary.

## Usage

Building on the example above, we can use Bullet Train Scope Validator to fix the problem like so:

First, add the following in our `Gemfile`:

```ruby
gem "bullet_train-scope_validator"
```

(Be sure to also run `bundle install` and restart your Rails server.)

Then we add a `scope: true` validation and `def valid_customers` method in the model, like so:

```ruby
class Deal < ApplicationRecord
  belongs_to :team
  belongs_to :customer

  validates :customer, scope: true

  def valid_customers
    team.customers
  end
end
```

If you're wondering what the connection between `validates :customer, scope: true` and `def valid_customers` is, it's just a convention that the former will call the latter based on the name of the attibute being validated. We've favored a full-blown method definition for this instead of simply passing in a proc into the validator because having a method allows us to also DRY up our form view to use the same definition of valid options, like so:

```erb
<%= form.collection_select(:customer_id, form.object.valid_customers, :id, :name) %>
```

So with that, you're done! Any attempts to stuff IDs will be met with an "invalid" Active Record error message.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bullet-train-co/bullet_train-scope_validator. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/bullet-train-co/bullet_train-scope_validator/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Bullet Train Scope Validator project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/bullet-train-co/bullet_train-scope_validator/blob/master/CODE_OF_CONDUCT.md).
