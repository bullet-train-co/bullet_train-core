# Two Factor Authentication

## Setup

run `bin/rails db:encryption:init` and use `bin/rails credentials:edit` to add the resulting keys to your `secrets.yml`

Add the following gems to your `Gemfile` and run `bundle install`

```ruby
gem "devise-two-factor"
gem "rqrcode"
```

If you haven't already done so, set the environment variable `RAILS_MASTER_KEY` with the contents of `config/master.key`. Note, this file should not be committed to git, and you should keep it in a safe place.

Now in the user's Account Details page there will be an option to enable two factor, and when enabled the two factor code will be required at login.
