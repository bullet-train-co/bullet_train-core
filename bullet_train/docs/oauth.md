# OAuth Providers
Bullet Train includes [Omniauth](https://github.com/omniauth/omniauth) by default which enables [Super Scaffolding](/docs/super-scaffolding) to easily add [any of the third-party OAuth providers in its community-maintained list of strategies](https://github.com/omniauth/omniauth/wiki/List-of-Strategies) for user-level authentication and team-level integrations via API and incoming webhooks.

For specific instructions on adding new OAuth providers, run the following on your shell:

```
bin/super-scaffold oauth-provider
```

## Stripe Connect Example
Similar to the "Tangible Things" template for [Super Scaffolding CRUD workflows](/docs/super-scaffolding.md), Bullet Train includes a Stripe Connect integration by default and this example also serves as a template for Super Scaffolding to implement other providers you might want to add.

## Dealing with Last Mile Issues

You should be able to add many third-party OAuth providers with Super Scaffolding without any manual effort. However, there are sometimes quirks from provider to provider, so if you need to dig in to get things working on a specific provider, here are the files you'll probably be looking for:

### Core Functionality
 - `config.omniauth` in `config/initializers/devise.rb`
   - Third-party OAuth providers are registered at the top of this file.
 - `app/controllers/account/oauth/omniauth_callbacks_controller.rb`
   - This controller contains all the logic that executes when a user returns back to your application after working their way through the third-party OAuth provider's workflow.
 - `omniauth_callbacks` in `config/routes.rb`
   - This file just registers the above controller with Devise.
 - `app/views/devise/shared/_oauth.html.erb`
   - This partial includes all the buttons for presentation on the sign in and sign up pages.
