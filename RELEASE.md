# How to release new versions of Bullet Train

In order to provide a smooth and easily-managable [upgrade process](https://bullettrain.co/docs/upgrades) we make use of tagged versions. Keeping
all of the tags and version numbers in sync is a pain to do manually so we use GitHub Actions to automate the process.

## 0. Prerequisites (one-time, but worth re-checking when a new package is added)

Publishing runs unattended in GitHub Actions, so the credentials have to work without a human at the keyboard.

**Ruby gems** are pushed with the `RUBYGEMS_AUTH_TOKEN` secret on the `core` repo, which `push.yml`
exposes as `GEM_HOST_API_KEY`. For that key to work it must be:

* owned by a rubygems.org account that is an **owner of every gem in this repo** — `gem push` is rejected
  per-gem, so a brand new gem will fail unless the key's account is added as an owner first
  (`gem owner <gem> --add <email>`),
* scoped to **"Push rubygem"** across **all gems**, not a hand-picked list (a gem-scoped key silently
  excludes any gem added after the key was created),
* created with the **per-key MFA checkbox turned off**. This is separate from your account MFA level —
  a key with MFA enabled demands an OTP on every push and can never work in CI, even when the account
  is set to "UI and gem signin".

**NPM packages** need no secret. They publish via OIDC trusted publishing (`permissions: id-token: write`
in `push.yml`, `npm publish --provenance`), which is configured per-package on npmjs.com and bound to this
repo and workflow rather than to anyone's token. A newly added npm package needs its trusted publisher
configured before its first release.

> When a new gem or package is added to this repo, check the above **before** running a release. Otherwise
> the rest of the packages publish and the new one doesn't.

## 1. Release new versions of the `core` Ruby gems and NPM packages

The `core` repo contains two different workflows for GitHub Actions that handle the entire process of releasing new versions of these ruby gems and npm packages.

* Go to the [↗️  Create Version Bump PR For Ruby Gems & NPM Packages](https://github.com/bullet-train-co/bullet_train-core/actions/workflows/version-bump.yml)
  workflow, click the "Run workflow" button, choose a Version Bump (patch, minor, or major), then click "Run workflow". (You generally would run this from the `main` branch.)

    * This workflow will produce a PR that bumps the version number in all of the `*.gemspec` and `package.json` files. [Here's an example.](https://github.com/bullet-train-co/bullet_train-core/pull/1471)

* Wait for tests to run and review the PR to make sure that it looks correct. At the time of this writing a version bump PR typically touches **150 lines in 40 files** (one `version.rb` and one `Gemfile.lock` per gem, plus the three `package.json` files and the top-level version file).

* Merge the PR, which will trigger the [🚅 ~ Tag, Relase & Push](https://github.com/bullet-train-co/bullet_train-core/actions/workflows/tag-release.yml) workflow.

    * This workflow will do the following:
        * [Tag](https://github.com/bullet-train-co/bullet_train-core/tags) the `main` branch with the corresponding verison tag. `v1.45.0` for instance.
        * Create a [GitHub Release](https://github.com/bullet-train-co/bullet_train-core/releases) from that tag which aggregates links to all of the included PRs.
          This provides a good place to add any additional release notes like breaking changes or new notable features.
          (I typically centralize additionl notes in the starter repo but occassionaly will mention something in the `core` notes.)
        * Build the Ruby gems and push them to [rubygems.org](https://rubygems.org/search?query=bullet_train)
        * Build the NPM packages and push them to [npmjs.com](https://www.npmjs.com/search?q=bullet-train)
            * If any package fails to publish, `bin/release-all` finishes the remaining packages and then
              fails the job with a summary of what was skipped. Fix the cause and re-run just the
              `Push / push` job — it re-attempts everything, and packages already published are skipped.
        * Build three Docker images based on the three `Dockerfile`s in the `dockerfiles/` directory and push them to the
          `bullet-train-co` organization [package repository](https://github.com/orgs/bullet-train-co/packages?repo_name=bullet_train-core).

## 2. Release a new version of the starter repo pointing to the newly release packages

The starter repo contains two different workflows for GitHub Actions that handle the entire process of releasing a new version of the app.

* Go to the [🚅 _ BT - Create Version Bump PR For Core Gems & NPM Packages](https://github.com/bullet-train-co/bullet_train/actions/workflows/version-bump.yml) workflow,
  enter the new version number from the `core` repo (`1.45.0` for example), and click "Run workflow".

    * This workflow will produce a PR that updates the BT version number in the `Gemfile` and `package.json` and also runs `bundle install` and `yarn install`
      to update `Gemfile.lock` and `yarn.lock`. [Here's an example.](https://github.com/bullet-train-co/bullet_train/pull/2483)

* Wait for tests to run and review the PR to make sure it looks correct. At the time of this writing a version bump PR touches **AT LEAST 53 lines in 4 files**.
  If dependencies of the core gems have changed the line count will be higher due to additional changes in `Gemfile.lock` or `yarn.lock`.

* Merge the PR, which will trigger the [🚅 _ BT - Tag & Release](https://github.com/bullet-train-co/bullet_train/actions/workflows/tag-release.yml) workflow.

    * This workflow will do the following:
        * [Tag](https://github.com/bullet-train-co/bullet_train/tags) the `main` branch with the corresponding verison tag. `v1.45.0` for instance.
        * Create a [GitHub Release](https://github.com/bullet-train-co/bullet_train/releases) from that tag which aggregates links to all of the included PRs.
          This provides a good place to add any additional release notes like breaking changes or new notable features.
        * Build two Docker images based on the the `Dockerfile` in the starter repo. We build an `arm` and an `amd` image and then merge them. The
          merged image is pushed to the `bullet-train-co` organization [package repository](https://github.com/orgs/bullet-train-co/packages?repo_name=bullet_train).

## 3. Update the demo site

Updating the [demo site](https://github.com/bullet-train-co/bullet_train-demo_site) immediately after cutting a new release is a good way to ensure that updates to downstream apps hasn't been broken with the new release.

* Go to the [↗️ Create Bullet Train Upgrade PR](https://github.com/bullet-train-co/bullet_train-demo_site/actions/workflows/upgrade-bullet-train.yml)
  workflow, click on the "Run workflow" button, and then the other "Run workflow" button. (Optionally supply a version number if you're a few versions behind
  and want to upgrade step-wise instead of all-at-once).

    * This workflow will produce a PR that bumps the version number in the `Gemfile` and `package.json` and pulls in any additional changes that were
      made to the starter repo. [Here's an example.](https://github.com/bullet-train-co/bullet_train-demo_site/pull/99)

* Wait for tests to run and review the PR, and optionally pull down the branch and run the demo site locally.

* Merge the PR, which will trigger the [🎥 Main CI (prod)](https://github.com/bullet-train-co/bullet_train-demo_site/actions/workflows/ci-cd-pipeline-main.yml) workflow.

    * This worklflow will run the tests and then deploy the demo site to Heroku.


## 4. Announce the new release in the Discord

I usually try to let people know the new version number, any breaking changes or new features, and links to the new releases in the starter and `core`
repos so they can check the diff and/or read more in the release notes.
