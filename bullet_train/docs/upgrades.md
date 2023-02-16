# Upgrading Your Bullet Train Application

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
git fetch starter-repo
````

### 3. Create a new "upgrade" branch off of your main branch.

```
git checkout main
git checkout -b updating-starter-repo
```

### 4. Merge in the newest stuff from Bullet Train and resolve any merge conflicts.

```
git merge starter-repo/main
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
git merge updating-starter-repo
git push origin main
git branch -d updating-starter-repo
```

Alternatively, if you're using GitHub, you can push the `updating-starter-repo` branch up and create a PR from it and let your CI integration do it's thing and then merge in the PR and delete the branch there. (That's what we typically do.)
