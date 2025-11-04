# Contributing to Bullet Train

To contribute to Bullet Train there are two main repos that are involved:

* [The starter repo](https://github.com/bullet-train-co/bullet_train) - This is the repo that you clone to start a new Bullet Train app.
* [The `core` repo](https://github.com/bullet-train-co/bullet_train-core) - This is where all (OK, most) of the gems live.

## Linking Ruby gems

When working on bug fixes or new features it can be useful to use a local copy of the `core` gems instead of the published versions.
You can do this in either the starter repo itself, or in a "downstream app" that has been created from the starter repo.

We have a convenience script in the starter repo at `bin/hack` which helps get things setup for you.

`bin/hack` supports two different models of organizing your filesystem for `core` development.

1.  The "nested repo approach" - If you run `bin/hack` with no arguments it will clone the `core` repo into your project at `local/bullet_train-core`.
    It will also attempt to open that repo in your editor/IDE.
2.  The "peer repo approach" - If you already have the `core` repo cloned you can pass the `--link` option to `bin/hack` followed by a path to `core`.
    For instance `bin/hack --link ../bullet_train-core`.

In either case `bin/hack` will modify the `Gemfile` in your project and change the lines for all of the `bullet_train*` gems to point to a local copy.

Lines that start like this:

```ruby
gem "bullet_train", BULLET_TRAIN_VERSION
```

Will become this:

```ruby
gem "bullet_train", path: "../bullet_train-core/bullet_train"
```

Once that's done you can start/restart your dev server and then chnages you make within your `core` repo will be reflected in your local app.

## Linking Javascript packages

If you need to make changes to any of the Javascript packages from the `core` gems the process is a little bit different.

We use `yalc` to handle the details of making a local package available to your local app.

First you need to go into the directory for the gem/package that you're working with, then build the JS package, and make it available to local projects using `yalc push`.
(Don't worry, you're not pushing to anywhere other than your local dev environment.)

So, if you're working with the `bullet_train-fields` JS package you'd do this:

```
cd bullet_train-core/bullet_train-fields
yarn build
yarn yalc push
```

After pushing you should see a line in your terminal that looks something like this:

```
@bullet-train/fields@1.32.0 published in store.
```

Next you can link that package into your local app or starter repo. (You'll be bouncing between the gem directory and your app directory, so it's convenient to use two different terminal sessions for this.)
Go into your app or starter repo directory and then use `yalc link` to connect your local package.

```
cd bullet_train
yarn yalc link @bullet-train/fields
```

Now your local app will be running with the JS code from your local copy.

As you're making changes you can test them out in your local app by building and pushing the package again.

So, for this example, back in the `bullet_train-core/bullet_train-fields` directory you can run:

```
yarn build; yarn yalc push
```

Now in addition to seeing a line about the package being published to the store, you should also seem some lines about it being pushed into your local app.

```
@bullet-train/fields@1.32.0 published in store.
Pushing @bullet-train/fields@1.32.0 in /Users/jgreen/projects/bullet-train-co/bullet_train
Package @bullet-train/fields@1.32.0 linked ==> /Users/jgreen/projects/bullet-train-co/bullet_train/node_modules/@bullet-train/fields
```

Each time that you rebuild and re-push the package the file watcher in your project (or starter repo) should notice the change and rebuild your assets.

## Managing cross-repo pull requests

Sometimes a particular change will require modifications to both the starter repo and the `core` repo. In these cases you should use the same branch
name in both repos. That will allow CI to hook them together and run tests in the right way.

Happy hacking!
