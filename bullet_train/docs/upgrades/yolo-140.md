# Upgrading Your Bullet Train Application to Version `1.4.0`

<div class="rounded-md border bg-amber-100 border-amber-200 py-4 px-5 mb-3 not-prose">
  <p class="text-sm text-amber-800 font-light mb-2">
    If you're already on version <code>1.4.0</code> or later you should use
    <a href="/docs/upgrades">The Stepwise Upgrade Method</a>
  </p>
  <p class="text-sm text-amber-800 font-light">
    <a href="/docs/upgrades/options">Learn about other upgrade options.</a>
  </p>
</div>

## Getting to `1.4.0`

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
git checkout -b updating-bullet-train-v1.4.0
```

### 4. Merge in the newest stuff from Bullet Train and resolve any merge conflicts.

```
git merge v1.4.0
```

It's quite possible you'll get some merge conflicts at this point. No big deal! Just go through and
resolve them like you would if you were integrating code from another developer on your team. We tend
to comment our code heavily, but if you have any questions about the code you're trying to understand,
let us know on Discord!

One of the files that's likely to have conflicts, and which can be the most frustrating to resolve is
`Gemfile.lock`. You can try to sort it out by hand, or you can checkout a clean copy and then let bundler
generate a new one that matches what you need:

```
git checkout HEAD -- Gemfile.lock
bundle install
```

If you choose to sort out `Gemfile.lock` by hand it's a good idea to run `bundle install` just to make
sure that your `Gemfile.lock` agrees with the new state of `Gemfile`.

Once you've resolved all the conflicts go ahead and commit the changes.

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

If anything fails, investigate the failures and get things working again, and commit those changes.

### 6. Merge into `main` and delete the branch.

```
git checkout main
git merge updating-bullet-train-v1.4.0
git push origin main
git branch -d updating-bullet-train-v1.4.0
```

Alternatively, if you're using GitHub, you can push the `updating-bullet-train-v1.4.0` branch up and create a PR from it and let your CI integration do it's thing and then merge in the PR and delete the branch there. (That's what we typically do.)


