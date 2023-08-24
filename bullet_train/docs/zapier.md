# Integrating with Zapier
Bullet Train provides out-of-the-box support for Zapier. New Bullet Train projects include a preconfigured Zapier CLI project that is ready to `zapier deploy`.

## Background
Zapier was designed to take advantage of an application's existing [REST API](/docs/api.md), [outgoing webhook capabilities](/docs/webhooks/outgoing.md), and OAuth2 authorization workflows. Thankfully for us, Bullet Train provides the first two and pre-configures Doorkeeper to provide the latter. We also have a smooth OAuth2 connection workflow that accounts for the mismatch between user-based OAuth2 and team-based multitenancy.

## Prerequisites
 - You must be developing in an environment with [tunneling enabled](/docs/tunneling.md).

## Getting Started in Development
First, install the Zapier CLI tooling and deploy:

```
cd zapier
yarn install
zapier login
zapier register
zapier push
```

Once the application is registered in your account, you can re-run seeds in your development environment and it will create a `Platform::Application` record for Zapier:

```
cd ..
rake db:seed
```

When you do this for the first time, it will output some credentials for you to go back and configure for the Zapier application, like so:

```
cd zapier
zapier env:set 1.0.0 \
  BASE_URL=https://andrewculver.ngrok.io \
  CLIENT_ID=... \
  CLIENT_SECRET=...
cd ..
```

You're done and can now test creating Zaps that react to example objects being created or create example objects based on other triggers.

## Deploying in Production
We haven't figured out a good suggested process for breaking out development and production versions of the Zapier application yet, but we'll update this section when we have.

## Future Plans
 - Extend Super Scaffolding to automatically add new resources to the Zapier CLI project. For now you have to extend the Zapier CLI definitions manually.

