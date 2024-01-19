# Getting Started

## Starting a New Project

Whether you want to build a new application with Bullet Train or contribute to Bullet Train itself, you should start by following the instructions on [the starter repository](https://github.com/bullet-train-co/bullet_train).

## Basic Techniques

If you're using Bullet Train for the first time, begin by learning these five important techniques:

1. Use `rails generate super_scaffold` to scaffold a new model:

    ```
    rails generate super_scaffold Project Team name:text_field
    ```

    In this example, `Team` refers to the immediate parent of the `Project` resource. For more details, just run `rails generate super_scaffold` or [read the documentation](/docs/super-scaffolding.md).

2. Use `rails generate super_scaffold:field` to add a new field to a model you've already scaffolded:

    ```
    rails generate super_scaffold:field Project description:trix_editor
    ```

    These first two points about Super Scaffolding are just the tip of the iceberg, so be sure to circle around and [read the full documentation](/docs/super-scaffolding.md).

3. Figure out which ERB views are powering something you see in the UI by:

    - Right clicking the element.
    - Selecting "Inspect Element".
    - Looking for the `<!-- BEGIN ... -->` comment above the element you've selected.

4. Figure out the full I18n translation key of any string on the page by adding `?show_locales=true` to the URL.

5. Use `bin/resolve` to figure out where framework or theme things are coming from and eject them if you need to customize something locally:

    ```
    bin/resolve Users::Base
    bin/resolve en.account.teams.show.header --open
    bin/resolve shared/box --open --eject
    ```

    Also, for inputs that can't be provided on the shell, there's an interactive mode where you can paste them:

    ```
    bin/resolve --interactive --eject --open
    ```

    And then paste any input, e.g.:

    ```
    <!-- BEGIN /Users/andrewculver/.rbenv/versions/3.1.2/lib/ruby/gems/3.1.0/gems/bullet_train-themes-light-1.0.10/app/views/themes/light/commentary/_box.html.erb -->
    ```
