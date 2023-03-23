# Overriding Framework Defaults

Most of Bullet Train's functionality is distributed via Ruby gems, not the starter template. We provide the `bin/resolve` tool to help developers figure out which Ruby gem packages are providing which classes, modules, views, and translations, and its usage is covered in the [Dealing With Indirection](/docs/indirection.md) section of the documentation.

However, sometimes you will need to do more than just understand where something is coming from and how it works in the framework. In some situations, you'll specifically want to change or override the default framework behavior. The primary workflow for doing this is much the same as the `bin/resolve` workflow for dealing with indirection in the first place, however, instead of just using `--open` to inspect the source of the framework-provided file, you can add `--eject` to have that file copied into the local repository. From there, it will act as a replacement for the framework-provided file, and you can modify the behavior as needed.

## The Important Role of Active Support Concerns in Bullet Train Customization

When it comes to object-oriented classes, wholesale copying framework files into your local repository just to be able to modify their behavior or extend them would quickly be untenable, as your app would no longer see upstream updates that would otherwise be incorporated into your application via `bundle update`.

For this reason, common points of extension like framework-provided models and controllers actually exist as a kind of "stub" in the local repository, but include their base functionality from framework-provided concerns, like so:

```
class User < ApplicationRecord
  include Users::Base

  # ...
end
```

In this case, for most customizations or extensions you would want to make, you don't need to eject `Users::Base` into your local repository. Instead, you can simply re-define methods from that concern in your local `User` model after the inclusion of the concern.
