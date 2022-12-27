# Zapier
Bullet Train provides support for Zapier out-of-the-box. New Bullet Train projects include a preconfigured Zapier CLI application that is ready to `zapier deploy`. 

## Background
Zapier was designed to take advantage of an application's existing [REST API](/docs/api.md), [outgoing webhook capabilities](/docs/webhooks/outgoing.md), and OAuth2 authorization workflows. Thankfully for us, Bullet Train provides the first two and pre-configures Doorkeeper to provide the latter.

## Prerequitesites
 - You must be developing in an environment with [tunneling enabled and properly configured](/docs/tunneling.md).

## Getting Started in Development
First, install the Zapier CLI tooling:

```
cd zapier
yarn install
zapier login
zapier register
zapier push
```

Once that application is registered, you can re-run seeds in your development environment and it will create a `Platform::Application` record for Zapier:

```
cd ..
rake db:seed
```

When you do this for the first time, it will output some credentials for you to configure with Zapier, like so:

```
cd zapier
zapier env:set 1.0.0 \
  BASE_URL=https://andrewculver.ngrok.io \
  CLIENT_ID=pfhUWOS8PAO7gvXJlopE8VjOYjSKzRaAjjMW40-oBIM \
  CLIENT_SECRET=w7s3pznCTrVeSFIFp8hnPEpAESGSNPqrzx5UZdVYSxg
```

## Deploying in Production
We haven't figured out a good suggested process for breaking out development and production versions of the Zapier application yet, but we'll update this section when we have.