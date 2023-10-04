# Options For Upgrading Your Bullet Train Application

## Quick Links

* [The YOLO Method (The original upgrade method)](/docs/upgrades/yolo.md)
* [The Stepwise Method - For `1.4.0` and above](/docs/upgrades)
* [Upgrade from any version to `1.4.0`](/docs/upgrades/yolo-140.md)
* [Upgrade from any version to `1.3.0`](/docs/upgrades/yolo-130.md)
* [Upgrade from `1.3.x` to `1.4.0`](/docs/upgrades/yolo-140.md)
* [Notable versions](/docs/upgrades/notable-versions)


## About the upgrade process

The vast majority of Bullet Train's functionality is distributed via Ruby gems, but those gems depend on certain
hooks and initializers being present in the hosting application. Those hooks and initializers are provided by the
[starter repository](https://github.com/bullet-train-co/bullet_train).

Starting in mid-August of 2023 we began to iterate on how we publish gems and how we ensure that the starter repo
will get the version of the gems that it expects.

Starting with version `1.3.0` we began to explicitly update the starter repo every time that we released new
versions of the Bullet Train gems. Unfortunately, at that time we were only making changes to `Gemfile.lock`
which kind of hides the dependencies, and is often a source of merge conflicts that can be hard to sort out.

Starting with version `1.4.0` we added explicit version numbers for all of the Bullet Train gems to `Gemfile`,
which is less hidden and is not as prone to having merge conflicts as `Gemfile.lock`.

As a result of these changes, there are a few different ways that you might choose to upgrade your application
depending on which version you're currently on.

[Be sure to check our Notable Versions list to see if there's anything tricky about the version you're moving to.](/docs/upgrades/notable-versions)

## How to find your current version

You can easily find your current version by running `bundle show | grep "bullet_train "`.

For example:

```
$ bundle show | grep "bullet_train "
  * bullet_train (1.3.20)
```

This app is on version `1.3.20`

## How to upgrade

Depending on what version you're starting on, and what version you want to get to, you have a few options.

In general your two main options are:

1. Upgrade directly from whatever version you happen to be on all the way to the latest published version.
2. Do a series of stepwise upgrades from the version you're on to the version you want to get to.

### Upgrade directly from any previous version to the latest version (aka The YOLO Method)

This was the original upgrade method that Bullet Train used for many years. It's still a perfectly useable way of
upgrading, though it feels a little... let's call it "uncontrolled" to some people. It can definitely lead to some
hairy merge conflicts if you haven't updated in a long time.

[Read more about The YOLO Method](/docs/upgrades/yolo.md)

### Upgrade from `1.4.0` (or later) to any later version (aka The Standard Stepwise Method)

This is the new standard upgrade method that we recommend. If you've ever upgraded a Rails app from version to version
this process should feel fairly similar.

[Read more about The Stepwise Method](/docs/upgrades)

### Upgrade from any previous verison to version `1.4.0` (a modified YOLO)

If you're on a version prior to `1.4.0` it can be a little tricky to do a stepwise upgrade to get to `1.4.0`. It's not
impossible (see below), but if you're feeling lucky you might start with making an attempt to upgrade your app directly to `1.4.0`.

[Read more about going directly to `1.4.0`](/docs/upgrades/yolo-140.md)

### Upgrade from any previous verison to version `1.3.0` (and through the `1.3.x` line)

Since we weren't tracking version numbers in `Gemfile` (only `Gemfile.lock`) it can be a little tricky to upgrade
directly to `1.3.0`. With a few extra steps in the upgrade process it's (hopefully) not too terrible.

[Read more about going directly to `1.3.0`](/docs/upgrades/yolo-130.md)

### Upgrade from `1.3.x` to version `1.4.0`

Once you make it to the end of the `1.3.x` line you only have one more step to get to the `1.4.0` branch. It's the
same instructions as if you wanted to upgrade to `1.4.0` from any previous version.

[Read more about going from `1.3.x` to `1.4.0`](/docs/upgrades/yolo-140.md)




