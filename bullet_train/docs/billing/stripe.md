# Bullet Train Billing for Stripe

When you're ready to start billing customers for the product you've created with Bullet Train, you can take advantage of our streamlined, commercial billing package that includes a traditional SaaS pricing page powered by Yaml configuration for products and prices.

We also provide a Stripe-specific adapter package with support for auto-configuring those products and prices in your Stripe account. It also takes advantage of completely modern Stripe workflows, like allowing customers to purchase your product with Stripe Checkout and later manage their subscription using Stripe Billing's customer portal. It also automatically handles incoming Stripe webhooks as well, to keep subscription state in your application up-to-date with activity that has happened on Stripe's platform.

## 1. Purchase Bullet Train Billing for Stripe

First, [purchase Bullet Train Billing for Stripe](https://buy.stripe.com/28o8zg4dBbrd59u7sM). Once you've completed this process, you'll be issued a private token for the Bullet Train Pro package server. (This process is currently completed manually, so please be patient.)

## 2. Install the Package

### 2.1. Add the Private Ruby Gems

You'll need to specify both Ruby gems in your `Gemfile`, since we have to specify a private source for both:

```ruby
source "https://YOUR_TOKEN_HERE@gem.fury.io/bullettrain" do
  gem "bullet_train-billing"
  gem "bullet_train-billing-stripe"
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

<aside><small>TODO Let's create a `rake bullet_train:billing:stripe:install` task.</small></aside>

### 2.4. Run Migrations

```
rake db:migrate
```

## 3. Configure Your Products

Bullet Train defines subscription plans and pricing options in `config/models/billing/products.yml` and defines the translatable elements of these plans in `config/locales/en/billing/products.en.yml`. We recommend just getting started with these plans to ensure your setup is working before customizing the attributes of these plans.

## 4. Configure Stripe

### 4.1. Create API Keys with Stripe

 - Create a Stripe account if you don't already have one.
 - Visit [https://dashboard.stripe.com/test/apikeys](https://dashboard.stripe.com/test/apikeys).
 - Create a new secret key.

**Note:** By default we're linking to the "test mode" page for API keys so you can get up and running in development. When you're ready to deploy to production, you'll have to repeat this step and toggle the "test mode" option off to provision real API keys for live payments.

### 4.2. Configure Stripe API Keys Locally

Edit `config/application.yml` and add your new Stripe secret key to the file:

```yaml
STRIPE_SECRET_KEY: sk_0CJw2Iu5wwIKXUDdqphrt2zFZyOCH
```

### 4.3. Populate Stripe with Locally Configured Products

Before you can use Stripe Checkout or Stripe Billing's customer portal, your locally configured products will have to be created on Stripe as well. To accomplish this, you can have all locally defined products automatically created on Stripe via API by running the following:

```
rake billing:stripe:populate_products_in_stripe
```

### 4.4. Add Additional Environment Variables

The script in the previous step will output some additional environment variables you need to copy into `config/application.yml`.


## 5. Wire Up Webhooks

Basic subscription creation will work without receiving and processing Stripe's webhooks. However, advanced payment workflows like SCA payments and customer portal cancelations and plan changes require receiving webhooks and processing them.

### 5.1. Ensure HTTP Tunneling is Enabled

Although Stripe provides free tooling for receiving webhooks in your local environment, the officially supported mechanism for doing so in Bullet Train is using [HTTP Tunneling with ngrok](/docs/tunneling.md). This is because we provide support for many types of webhooks across different platforms and packages, so we already need to have ngrok in play.

Ensure you've completed the steps from [HTTP Tunneling with ngrok](/docs/tunneling.md), including updating `BASE_URL` in `config/application.yml` and restarting your Rails server.

### 5.2. Enable Stripe Webhooks

 - Visit [https://dashboard.stripe.com/test/webhooks/create](https://dashboard.stripe.com/test/webhooks/create).
 - Use the default "add an endpoint" form.
 - Set "endpoint URL" to `https://YOUR-SUBDOMAIN.ngrok.io/webhooks/incoming/stripe_webhooks`.
 - Under "select events to listen to" choose "select all events" and click "add events".
 - Finalize the creation of the endpoint by clicking "add endpoint".

### 5.3. Configure Stripe Webhooks Signing Secret

After creating the webhook endpoint, click "reveal" under the heading "signing secret". Copy the `whsec_...` value into your `config/application.yml` like so:

```yaml
STRIPE_WEBHOOKS_ENDPOINT_SECRET: whsec_vchvkw3hrLK7SmUiEenExipUcsCgahf9
```

### 5.4. Test Sample Webhook Delivery

 - Restart your Rails server with `rails restart`.
 - Trigger a test webhook just to ensure it's resulting in an HTTP status code of 201.

## 6. Test Creating a Subscription

Bullet Train comes preconfigured with a "freemium" plan, so new and existing accounts will continue to work as normal. A new "billing" menu item will appear and you can test subscription creation by clicking "upgrade" and selecting one of the two plans presented.

You should be in "test mode" on Stripe, so when prompted for a credit card number, you can enter `4242 4242 4242 4242`.

## 7. Configure Stripe Billing's Customer Portal

  - Visit [https://dashboard.stripe.com/test/settings/billing/portal](https://dashboard.stripe.com/test/settings/billing/portal).
  - Complete all required fields.
  - Be sure to add all of your actively available plans under "products".

This "products" list is what Stripe will display to users as upgrade and downgrade options in the customer portal. You shouldn't list any products here that aren't properly configured in your Rails app, otherwise the resulting webhook will fail to process. If you want to stop offering a plan, you should remove it from this list as well.

## 8. Finalize Webhooks Testing by Managing a Subscription

In the same account where you created your first test subscription, go into the "billing" menu and click "manage" on that subscription. This will take you to the Stripe Billing customer portal.

Once you're in the customer portal, you should test upgrading, downgrading, and canceling your subscription and clicking "⬅ Return to {Your Application Name}" in between each step to ensure that each change you're making is properly reflected in your Bullet Train application. This will let you know that webhooks are being properly delivered and processed and all the products in both systems are properly mapped in both directions.

## 9. Rinse and Repeat Configuration Steps for Production

As mentioned earlier, all of the links we provided for configuration steps on Stripe were linked to the "test mode" on your Stripe account. When you're ready to launch payments in production, you will need to:

 - Complete all configuration steps again in the live version of your Stripe account. You can do this by following all the links in the steps above and toggling the "test mode" switch to visit the live mode version of each page.
 - After creating a live API key, configure `STRIPE_SECRET_KEY` in your production environment.
 - Run `STRIPE_SECRET_KEY=... rake billing:stripe:populate_products_in_stripe` (where `...` is your live secret key) in order to create live versions of your products and prices.
 - Copy the environment variables output by that rake task into your production environment.
 - Configure a live version of your webhooks endpoint for the production environment by following the same steps as before, but replacing the ngrok host with your production host in the endpoint URL.
 - After creating the live webhooks endpoint, configure the corresponding signing secret as the `STRIPE_WEBHOOKS_ENDPOINT_SECRET` enviornment variable in your production environment.

## 10. You should be done!

[Let us know on Discord](http://discord.gg/bullettrain) if any part of this guide was not clear or could be improved!