# Upgrading Your Bullet Train Application to Version `1.3.0` and through the `1.3.x` line

<div class="rounded-md border bg-amber-100 border-amber-200 py-4 px-5 mb-3 not-prose">
  <p class="text-sm text-amber-800 font-light mb-2">
    If you're already on version <code>1.4.0</code> or later you should use
    <a href="/docs/upgrades">The Stepwise Upgrade Method</a>
  </p>
  <p class="text-sm text-amber-800 font-light">
    <a href="/docs/upgrades/options">Learn about other upgrade options.</a>
  </p>
</div>

## Getting to `1.3.0`

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
git fetch --tags bullet-train
```

### 3. Create a new "upgrade" branch off of your main branch.

```
git checkout main
git checkout -b updating-bullet-train-v1.3.0
```

### 4. Merge in the newest stuff from Bullet Train and resolve any merge conflicts.

```
git merge v1.3.0
```

It's quite possible you'll get some merge conflicts at this point. No big deal! Just go through and
resolve them like you would if you were integrating code from another developer on your team. We tend
to comment our code heavily, but if you have any questions about the code you're trying to understand,
let us know on Discord!

One of the files that's likely to have conflicts, and which can be the most frustrating to resolve is
`Gemfile.lock`. Unfortunately there are important changes in that file that we'll want to preserve.
Luckily there's a way to do it without having to resolve conflicts manually. We'll handle that in the
next step. For now you can just skip the updates in that file:

```
git checkout HEAD -- Gemfile.lock
```

Once you've resolved all the conflicts go ahead and commit the changes.

```
git diff
git add -A
git commit -m "Upgrading Bullet Train."
```

### 5. Update `Gemfile`

Now we need to handle the situation with `Gemfile.lock` that we side-stepped earlier. you should open
up your `Gemfile` and find this block of gems:

```ruby
# BULLET TRAIN GEMS
# This section is the list of Ruby gems included by default for Bullet Train.


# Core packages.
gem "bullet_train"
gem "bullet_train-super_scaffolding"
gem "bullet_train-api"
gem "bullet_train-outgoing_webhooks"
gem "bullet_train-incoming_webhooks"
gem "bullet_train-themes"
gem "bullet_train-themes-light"
gem "bullet_train-integrations"
gem "bullet_train-integrations-stripe"


# Optional support packages.
gem "bullet_train-sortable"
gem "bullet_train-scope_questions"
gem "bullet_train-obfuscates_id"
```

Replace that entire block with this block:

```ruby
# BULLET TRAIN GEMS
# This section is the list of Ruby gems included by default for Bullet Train.

# We use a constant here so that we can ensure that all of the bullet_train-*
# packages are on the same version.
BULLET_TRAIN_VERSION = "1.3.0"

# Core packages.
gem "bullet_train", BULLET_TRAIN_VERSION
gem "bullet_train-super_scaffolding", BULLET_TRAIN_VERSION
gem "bullet_train-api", BULLET_TRAIN_VERSION
gem "bullet_train-outgoing_webhooks", BULLET_TRAIN_VERSION
gem "bullet_train-incoming_webhooks", BULLET_TRAIN_VERSION
gem "bullet_train-themes", BULLET_TRAIN_VERSION
gem "bullet_train-themes-light", BULLET_TRAIN_VERSION
gem "bullet_train-integrations", BULLET_TRAIN_VERSION
gem "bullet_train-integrations-stripe", BULLET_TRAIN_VERSION

# Optional support packages.
gem "bullet_train-sortable", BULLET_TRAIN_VERSION
gem "bullet_train-scope_questions", BULLET_TRAIN_VERSION
gem "bullet_train-obfuscates_id", BULLET_TRAIN_VERSION

# Core gems that are dependencies of gems listed above. Technically they
# shouldn't need to be listed here, but we list them so that we can keep
# verion numbers in sync.
gem "bullet_train-fields", BULLET_TRAIN_VERSION
gem "bullet_train-has_uuid", BULLET_TRAIN_VERSION
gem "bullet_train-roles", BULLET_TRAIN_VERSION
gem "bullet_train-scope_validator", BULLET_TRAIN_VERSION
gem "bullet_train-super_load_and_authorize_resource", BULLET_TRAIN_VERSION
gem "bullet_train-themes-tailwind_css", BULLET_TRAIN_VERSION
```

(We have to do this since we didn't start explicitly tracking versions until `1.4.0` and
want to make sure that our gem versions match what the starter repo expects.)

Then run `bundle install`

Then go ahead and commit the changes.

```
git diff
git add -A
git commit -m "Upgrading Bullet Train gems."
```

### 5. Run Tests.

```
rails test
rails test:system
```

If anything fails, investigate the failures and get things working again, and commit those changes.

### 6. Merge into `main` and delete the branch.

```
git checkout main
git merge updating-bullet-train-v1.3.0
git push origin main
git branch -d updating-bullet-train-v1.3.0
```

Alternatively, if you're using GitHub, you can push the `updating-bullet-train-v1.3.0` branch up and create a PR from it and let your CI integration do it's thing and then merge in the PR and delete the branch there. (That's what we typically do.)


## Stepping to `1.3.x`

Before doing this you should have already followed the instructions above to get to version `1.3.0`.

For purposes of this example we'll assume that you're stepping up from `1.3.0` to `1.3.1`.

[Be sure to check our Notable Versions list to see if there's anything tricky about the version you're moving to.](/docs/upgrades/notable-versions)

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
git fetch --tags bullet-train
```

### 3. Create a new "upgrade" branch off of your main branch.

```
git checkout main
git checkout -b updating-bullet-train-v1.3.1
```

### 4. Merge in the newest stuff from Bullet Train and resolve any merge conflicts.

```
git merge v1.3.1
```

It's quite possible you'll get some merge conflicts at this point. No big deal! Just go through and
resolve them like you would if you were integrating code from another developer on your team. We tend
to comment our code heavily, but if you have any questions about the code you're trying to understand,
let us know on Discord!

One of the files that's likely to have conflicts, and which can be the most frustrating to resolve is
`Gemfile.lock`. Unfortunately there are important changes in that file that we'll want to preserve.
Luckily there's a way to do it without having to resolve conflicts manually. We'll handle that in the
next step. For now you can just skip the updates in that file:

```
git checkout HEAD -- Gemfile.lock
```

Once you've resolved all the conflicts go ahead and commit the changes.

```
git diff
git add -A
git commit -m "Upgrading Bullet Train."
```

### 5. Update `Gemfile`

Now we need to handle the situation with `Gemfile.lock` that we side-stepped earlier. you should open
up your `Gemfile` and find this line:

```ruby
BULLET_TRAIN_VERSION = "1.3.0"
```

Update that line with the new version you're moving to:

```ruby
BULLET_TRAIN_VERSION = "1.3.1"
```

(We have to do this since we didn't start explicitly tracking versions until `1.4.0` and
want to make sure that our gem versions match what the starter repo expects.)

Then run `bundle install`

Then go ahead and commit the changes.

```
git diff
git add -A
git commit -m "Upgrading Bullet Train gems."
```

### 5. Run Tests.

```
rails test
rails test:system
```

If anything fails, investigate the failures and get things working again, and commit those changes.

### 6. Merge into `main` and delete the branch.

```
git checkout main
git merge updating-bullet-train-v1.3.1
git push origin main
git branch -d updating-bullet-train-v1.3.1
```

Alternatively, if you're using GitHub, you can push the `updating-bullet-train-v1.3.1` branch up and create a PR from it and let your CI integration do its thing and then merge in the PR and delete the branch there. (That's what we typically do.)
