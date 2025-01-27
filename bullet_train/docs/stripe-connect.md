# Stripe Connect

Bullet Train comes with a Stripe Connect integration ready to go. All you have to do is configure your Stripe account and set
a couple of ENV variables.

Once Stripe Connect is configured it allows for two things:

1.  Users can connect their Stripe account as a form of sign in to your app. A "Sign in with Stripe" button will appear on the
    login form. Users who have already signed up with email address and password will continue to be able to use those credentials,
    but they'll also be able to connect a Stripe account for auth.
2.  Teams can add a new Stripe Installation for marketplace type sales. (It's up to you to build out the marketplace and the sales process
    we just make it easy to allow your users to connect their Stripe accounts.)

## Initial Setup

In order to get things working you'll need to configure the OAuth settings under "Settings > Connect" in your Stripe account.

*  [OAuth Settings for test mode](https://dashboard.stripe.com/test/settings/connect/onboarding-options/oauth)
*  [OAuth Settings for production](https://dashboard.stripe.com/settings/connect/onboarding-options/oauth)

### Set the `STRIPE_CLIENT_ID` ENV var

From the OAuth Settings page you need to grab the "Test client ID" and/or "Live client ID" depending on whether you're configuring test mode
or live mode. Copy that value and set is as the `STRIPE_CLIENT_ID` ENV var in your environment.

### Enable OAuth

On the Stripe OAuth Settings page make sure that the switch for "Enable OAuth"/"OAuth for Stripe Dashboard accounts" is turned on.

### Set your redirect URL

In the "Redirects" section of the OAuth Settings click "+ Add URI" and set the callback URL. The path for the callback is
`/users/auth/stripe_connect/callback` and the host will vary depending on your environment and how you access it.

For test mode on localhost you can usually set the redirect URL to be:

```
http://localhost:3000/users/auth/stripe_connect/callback
```

For live mode it will need to be an `https` URL and it should point to your production environment.

```
https://your-apps-fancy-domain-goes-here/users/auth/stripe_connect/callback
```

### Set the `STRIPE_SECRET_KEY` ENV var

Finally you need to set the secret key. These can be found under "Developers > API Keys"

*  [API Keys for test mode](https://dashboard.stripe.com/test/apikeys)
*  [API Keys for production](https://dashboard.stripe.com/apikeys)

Copy the "Secret key" value and set is as the `STRIPE_SECRET_KEY` ENV var in the appropriate environment.

## Using Stripe Connect

Once you've configured your Stripe account and set the necessary ENV vars you'll need to restart your server.

### Create a second Stripe account for testing.

The Stripe account that you configured above is kind of a "host account" that "owns" the connections between your app and _other_ Stripe accounts
(Stripe accounts that are not your app). So in order to test connections you'll need a second Stripe account.

### Using Stripe Connect for sign in

Under the user menu in your Bullet Train app, go to the "Account Details" link (`/account/users/XXX/edit`).

There you should see a section for "Connected Stripe Accounts".

Click the "Connect Stripe Account" button and then follow the prompts. At the end of the process you should be redirected back to your
"Account Details" screen and you should see that you now have a Stripe account connected.

### Using Stripe Connect for marketplace sales

In the top menu you should now see an "Integrations" menu with a "Stripe Installations" menu item. When you go there you'll be able to
add a new Stripe Installation. The process is pretty much the same as connecting a new account for auth purposes.
