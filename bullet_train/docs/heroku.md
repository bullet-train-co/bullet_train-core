# Deploying to Heroku

When you're ready to deploy to Heroku, it's highly recommended you use this button:

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=http://github.com/bullet-train-co/bullet_train)

This button leverages the configuration found in `app.json`, including sensible production-ready defaults for dyno formation, third-party services, buildpack configuration, etc. The resources provisioned will cost about **$140/month**.

## What's Included?

### Required Add-Ons
We've included the "entry-level but production-grade" service tier across the board for:

 - [Heroku Postgres](https://elements.heroku.com/addons/heroku-postgresql)
 - [Heroku Redis](https://elements.heroku.com/addons/heroku-redis) to support Sidekiq and Action Cable.
 - [Memcachier](https://elements.heroku.com/addons/memcachier) to support Rails Cache.
 - [Bucketeer](https://elements.heroku.com/addons/bucketeer) to support off-server file uploads backed by AWS S3.
 - [Cloudinary](https://cloudinary.com) to support off-server image uploads and ImageMagick processing.
 - [Heroku Scheduler](https://elements.heroku.com/addons/scheduler) for cron jobs.
 - [Rails Autoscale](https://railsautoscale.com) for best-of-breed reactive performance monitoring.
 - [Honeybadger](https://www.honeybadger.io) and [Sentry](https://elements.heroku.com/addons/sentry), both free, for redundant error tracking.
 - [Expedited Security](https://expeditedsecurity.com)'s [Real Email](https://elements.heroku.com/addons/realemail) to reduce accounts created with fake and unreachable emails, which will subsequently hurt your email deliverability.

## Additional Required Steps
Even after using the above button, there are a few steps that need to be performed manually using the [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli):

### 1. Add Heroku as a Remote in Your Local Repository

```
heroku git:remote -a YOUR_HEROKU_APP_NAME
```

After this, you'll be able to deploy updates to your app like so:

```
git push heroku main
````

### 2. Enabling Runtime Dyno Metadata
We include [Honeybadger](http://honeybadger.io) and Sentry (both at a free tier) for redundant error tracking by default. Sentry requires the following Heroku labs feature to be enabled:

```
heroku labs:enable runtime-dyno-metadata
```

### 3. Improve Boot Time
You can cut your application boot time in half by enabling the following Heroku Labs feature. See [this blog post](https://dev.to/dbackeus/cut-your-rails-boot-times-on-heroku-in-half-with-a-single-command-514d) for more details.

```
heroku labs:enable build-in-app-dir
```

### 4. Adding Your Actual Domain

The most common use case for Bullet Train applications is to be hosted at some appropriate subdomain (e.g. `app.YOURDOMAIN.COM`) while a marketing site is hosted with a completely different service at the apex domain (e.g. just `YOURDOMAIN.COM`) or `www.YOURDOMAIN.COM`. To accomplish this, do the following in your shell:

```
heroku domains:add app.YOURDOMAIN.COM
```

The output for this command will say something like:

```
Configure your app's DNS provider to point to the DNS Target SOMETHING-SOMETHING-XXX.herokudns.com.
```

On most DNS providers this means going into the DNS records for `YOURDOMAIN.COM` and adding a *CNAME* record for the `app` subdomain with a value of `SOMETHING-SOMETHING-XXX.herokudns.com` (except using the actual value provided by the Heroku CLI) and whatever TTL refresh rate you desire. I always set this as low as possible at first to make it easier to fix any mistakes I've made.

After you've added that record, you need to update the following environment settings on the Heroku app:

```
heroku config:set BASE_URL=https://app.YOURDOMAIN.COM
heroku config:set MARKETING_SITE_URL=https://YOURDOMAIN.COM
```

You'll also need to enable Heroku's Automated Certificate Management to have them handle provisioning and renewing your Let's Encrypt SSL certificates:

```
heroku certs:auto:enable
heroku certs:auto
```

You should be done now and your app should be available at `https://app.YOURDOMAIN.COM/account` and any hits to `https://app.YOURDOMAIN.COM` (e.g. when users sign out, etc.) will be redirected to your marketing site.

### 5. Configure CORS on Your Bucketeer S3 Bucket

Before you can upload to your freshly provisioned S3 bucket, you need to run (on Heroku) a rake task we've created for you to set the appropriate CORS settings.

```
heroku run rake aws:set_cors
```

Note: If you change `ENV["BASE_URL"]`, you need to re-run this task.
