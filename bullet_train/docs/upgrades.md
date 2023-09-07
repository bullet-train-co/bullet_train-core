# Upgrading Your Bullet Train Application

<div class="rounded-md border bg-amber-100 border-amber-200 py-4 px-5 mb-3 not-prose">
  <h3 class="text-sm text-amber-800 font-light">
    Note: These ugrade steps have recently changed.
  </h3>
</div>

## Quick Links

* [The Standard Method - Step-wise updates after version `1.4.0`](/docs/upgrades#the-standard-method)
* [Upgrade from any verison to `1.4.0`](/docs/upgrades/yolo-140.md)
* [Upgrade from any version to `1.3.0`](/docs/upgrades/yolo-130.md)
* [Upgrade from `1.3.x` to `1.4.0`](/docs/upgrades/yolo-140.md)
* [The YOLO Method (The original upgrade method.)](/docs/upgrades/yolo.md)

## About the upgrade process

The vast majority of Bullet Train's functionality is distributed via Ruby gems, but those gems depend on certain
hooks and initializers being present in the hosting application. Those hooks and initializers are provided by the
starter repository.

Starting in mid-August of 2023 we began to iterate on how we publish gems and how we ensure that the starter repo
will get the version of the gems that it expects.

Starting with version `1.3.0` we began to explicitly update the starter repo every time that we released new
versions of the Bullet Train gems. Unfortunately, at that time we were only making changes to `Gemfile.lock`
which kind of hides the dependencies, and is often a source of merge conflicts that can be hard to sort out.

Starting with version `1.4.0` we added explicit version numbers for all of the Bullet Train gems to `Gemfile`,
which is less hidden and is not as prone to having merge conflicts as `Gemfile.lock`.

As a result of these changes, there are a few different ways that you might choose to upgrade your application
depending on which version you're currently on.

## How to find your current version

1. First open `Gemfile` in your application and look/search for a line that begins with `BULLET_TRAIN_VERSION`.
   For instance:
    ```ruby
    BULLET_TRAIN_VERSION = "1.4.0"
    ```
   If your `Gemfile` has such a line, that should be the verison you're on. In this case `1.4.0`.

2. If you don't have a `BULLET_TRAIN_VERSION` line in `Gemfile`, then you need to open `Gemfile.lock` and look/search
   for a line for the `bullet_train` gem. For instance:
   ```ruby
   bullet_train (1.2.24)
   ```
   In this case the app is on version `1.2.24`

## How to upgrade

Depending on what version you're starting on, and what version you want to get to, you have a few options.

In general your two main options are:

1. Upgrade directly from whatever version you happen to be on all the way to the latest published version.
2. Do a series of step-wise upgrades from the version you're on to the version you want to get to.

### Upgrade directly from any previous version to the latest version (aka The YOLO Method)

This was the original upgrade method that Bullet Train used for many years. It's still a perfectly useable way of
upgrading, though it feels a little... let's call it "uncontrolled" to some people. It can definitely lead to some
hairy merge conflicts if you haven't updated in a long time.

[Read more about The YOLO Method](/docs/upgrades/yolo.md)

### Upgrade from `1.4.0` (or later) to any later version (aka The Standard Method)

This is the new standard upgrade method that we recommend. If you've ever upgraded a Rails app from version to verison
this process should feel fairly similar.

[Read more about The Standard Method](/docs/upgrades/yolo-140.md)

### YOLO from any previous verison to version `1.4.0`

If you're on a version prior to `1.4.0` it's a little tricky to do a step-wise upgrade to get to `1.4.0`. It's not
impossible (see below), but we recommend starting with making an attempt to YOLO your app directly to `1.4.0`.

[Read more about going directly to `1.4.0`](/docs/upgrades/yolo-140.md)

### Upgrade from any previous verison to version `1.3.0` (and through the `1.3.x` line)

Since we weren't tracking version numbers in `Gemfile` (only `Gemfile.lock`) it can be a little tricky to upgrade
directly to `1.3.0`. With a few extra steps in the upgrade process it's (hopefully) not too terrible.

[Read more about going directly to `1.3.0`](/docs/upgrades/yolo-130.md)

### Upgrade from `1.3.x` to version `1.4.0`

Once you make it to the end of the `1.3.x` line you only have one more step to get to the `1.4.0` branch. It's the
same instructions as if you wanted to YOLO to `1.4.0` from any previous version.

[Read more about going from `1.3.x` to `1.4.0`](/docs/upgrades/yolo-140.md)


## Upgrading the Framework

The vast majority of Bullet Train's functionality is distributed via Ruby gems, so you can pull the latest updates by running `bundle update`.

## Pulling Updates from the Starter Repository

There are times when you'll want to pull updates from the starter repository into your local application. Thankfully, `git merge` provides us with the perfect tool for just that. You can simply merge the upstream Bullet Train repository into your local repository. If you haven’t tinkered with the starter repository defaults at all, then this should happen with no meaningful conflicts at all. Simply run your automated tests (including the comprehensive integration tests Bullet Train ships with) to make sure everything is still working as it was before.

If you _have_ modified some starter repository defaults _and_ we also happened to update that same logic upstream, then pulling the most recent version of the starter repository should cause a merge conflict in Git. This is actually great, because Git will then give you the opportunity to compare our upstream changes with your local customizations and allow you to resolve them in a way that makes sense for your application.

### 1. Make sure you're working with a clean local copy.

```
git status
```

If you've got uncommitted or untracked files, you can clean them up with the following.

```
# ⚠️ This will destroy any uncommitted or untracked changes and files you have locally.
git checkout .
git clean -d -f
```

### 2. Fetch the latest and greatest from the Bullet Train repository.

```
git fetch bullet-train
```

### 3. Create a new "upgrade" branch off of your main branch.

```
git checkout main
git checkout -b updating-bullet-train
```

### 4. Merge in the newest stuff from Bullet Train and resolve any merge conflicts.

```
git merge bullet-train/main
```

It's quite possible you'll get some merge conflicts at this point. No big deal! Just go through and resolve them like you would if you were integrating code from another developer on your team. We tend to comment our code heavily, but if you have any questions about the code you're trying to understand, let us know on Discord!

```
git diff
git add -A
git commit -m "Upgrading Bullet Train."
```

### 5. Run Tests.

```
rails test
rails test:system
```

### 6. Merge into `main` and delete the branch.

```
git checkout main
git merge updating-bullet-train
git push origin main
git branch -d updating-bullet-train
```

Alternatively, if you're using GitHub, you can push the `updating-bullet-train` branch up and create a PR from it and let your CI integration do it's thing and then merge in the PR and delete the branch there. (That's what we typically do.)
