# Deploying to Heroku

## Taking Bullet Train for a test drive

If you just want to take this project for a test drive on Heroku without starting your own application you can use this button:

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://www.heroku.com/deploy?template=https://github.com/bullet-train-co/bullet_train)

This button leverages the configuration found in `app.json`, including sensible demo-ready defaults for dyno formation, third-party services, buildpack configuration, etc.

The resources provisioned will cost about **$22/month**.

**Please note:** The resources provisioned via `app.json` are intended to be used for quickly launching your brand new app so that you can demo it easily. When you're ready to go into production you'll want to make some changes to these resources. See the section at the bottom of this page.

We also have a a demo site that you can try without needing to deploy anything. You can [sign up if you haven't tried it before](/users/sign_up) or if you can [sign in if you've already given it a test run](/users/sign_in).

## What's Included?

### Required Add-Ons

We've included the "entry-level" service tier across the board for:

 - [Heroku Postgres](https://elements.heroku.com/addons/heroku-postgresql)
 - [Heroku Redis](https://elements.heroku.com/addons/heroku-redis) to support Sidekiq and Action Cable.
 - [Memcachier](https://elements.heroku.com/addons/memcachier) to support Rails Cache.
 - [Cloudinary](https://cloudinary.com) to support off-server image uploads and ImageMagick processing.
 - [Heroku Scheduler](https://elements.heroku.com/addons/scheduler) for cron jobs.
 - [Rails Autoscale](https://railsautoscale.com) for best-of-breed reactive performance monitoring.
 - [Honeybadger](https://www.honeybadger.io) for error tracking.
 - [Expedited Security](https://expeditedsecurity.com)'s [Real Email](https://elements.heroku.com/addons/realemail) to reduce accounts created with fake and unreachable emails, which will subsequently hurt your email deliverability.

## Deploying a real application

When you're ready to deploy your own application based on Bullet Train there are a few steps that need to be performed manually using the [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli):

### 1. Clone the repo and bootstrap your app

Follow the [normal instructions for getting started](https://github.com/bullet-train-co/bullet_train?tab=readme-ov-file#building-a-new-application-with-bullet-train)
and during the `bin/configure` process be sure to choose to push your app to GitHub and to choose to add a "Deploy to Heroku" button.

After doing that you'll have a copy of the starter repo that has been customized with your application name and settings.

### 2. Deploy to Heroku using your own "Deploy to Heroku" button

Now go to your repo on GitHub and look for the "Deploy to Heroku" button.

If you don't have one (or if it's not working right) you can add a new button to your README by running:

```
./bin/configure-scripts/deploy_button_heroku.rb
```

After generating the button be sure to commit the change and push to your GitHub repo.

Click the "Deploy to Heroku" button in your repo and you'll be taken to a screen where you can start the deployment process.

### 3. Add Heroku as a Remote in Your Local Repository

Once your application has been created use the name that you gave it to set up a git remote for `heroku`:

```
heroku git:remote -a YOUR_HEROKU_APP_NAME
```

### 4. Push to heroku

After this, you'll be able to deploy updates to your app like so:

```
git push heroku main
```

## Configuring automatic deploys

We include some pre-built workflows for GitHub actions that can run the test suite and automatically deploy your code to
either a staging or a production environment.

`.github/workflows/ci-cd-pipeline-main.yml` is a workflow that is run any time that new code lands on your `main` branch.

At the bottom of the workflow is a block for automatically deploying to Heroku. It's commented out by default but you can un-comment
it and set the `heroku-app-name` value to be the name of your new app in Heroku.

If you don't want to deploy directly to production you could create a staging app in Heroku (by following the directions above but giving
the new app a different name) and then add your staging and production apps to a pipeline. Then you could configure `ci-cd-pipeline-main.yml`
to deploy to your staging app. Then you can use the Heroku pipeline functionality to promote versions of your app from staging to production.

If you don't want to use Heroku pipelines but still want to have automated deploys to production that are triggered intentionally (not on every
change to `main`) then you could duplicate `ci-cd-pipeline-main.yml` to something like `ci-cd-pipeline-production.yml` and change the conditions
under which the workflow is run.

For instance if you wanted to automatically deploy to production when a new verison tag is added to your GitHub repo you could change the `on:` block
in the workflow file to be something like this:

```
on:
  push:
    tags:
      - 'v[0-9]+.[0-9]+.[0-9]+'
```

With that you could then deploy to prod by doing something like this:

```
git tag v0.0.1
git push origin --tags
```

Then the workflow would be triggered, it would run your test suite, and then deploy to whichever app you've configured in the workflow file.

## Additional setup

### 1. Improve Boot Time

You can cut your application boot time in half by enabling the following Heroku Labs feature. See [this blog post](https://dev.to/dbackeus/cut-your-rails-boot-times-on-heroku-in-half-with-a-single-command-514d) for more details.

```
heroku labs:enable build-in-app-dir
```

### 2. Adding Your Actual Domain

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

### 3. Configure CORS on Your S3 Bucket

Before you can upload to your freshly provisioned S3 bucket, you need to run (on Heroku) a rake task we've created for you to set the appropriate CORS settings.

```
heroku run rake aws:set_cors
```

Note: If you change `ENV["BASE_URL"]`, you need to re-run this task.

## Getting ready for production

When you're ready to launch your app in production you probably don't want to use the entry-level resources that we provision via `app.json`


### 1. Use standard dynos instead of basic

To update your `web` and `worker` processes to use `standard-1` dynos instead of `basic`:

```
heroku ps:type web=standard-1x
heroku ps:type worker=standard-1x
```

### 2. Upgrade your database

Pick the plan that matches the features you need: https://elements.heroku.com/addons/heroku-postgresql

Then follow the instructions here: https://devcenter.heroku.com/articles/updating-heroku-postgres-databases

### 3. Upgrade your redis instance

Pick the plan that matches the features you need: https://elements.heroku.com/addons/heroku-redis

Then follow the instructions here: https://devcenter.heroku.com/articles/heroku-redis-version-upgrade

### 4. Upgrade any other resources

Use `heroku addons` to see which addons you currently have installed. Double check the features that are included with your current plan and make sure they're sufficient for your needs in production.
