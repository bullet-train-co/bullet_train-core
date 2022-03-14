# Getting Started

## Starting a New Project
To get started with Bullet Train, follow the instructions in our [starter repository](https://github.com/bullet-train-co/bullet_train).

## Basic Techniques
If you're using Bullet Train for the first time, once you've got your application up and running locally, start by learning these five techniques:

1. Use `rails g model` to create and `bin/super-scaffold` to scaffold a new model:

    ```
    $ rails g model Project team:references name:string
    $ bin/super-scaffold crud Project Team name:text_field
    ```

    In this example, `Team` refers to the immediate parent of the `Project` resource. For more details, just run `bin/super-scaffold` or [read the documentation](/docs/super-scaffolding.md).

2. Use `rails g migration` and `bin/super-scaffold` to add a new field to a model you've already scaffolded:

    ```
    $ rails g migration add_description_to_projects description:text
    $ bin/super-scaffold crud-field Project description:trix_editor
    ```

    These first two points about Super Scaffolding are just the tip of the iceberg, so be sure to circle around and [read the full documentation](/docs/super-scaffolding.md).

3. Figure out which ERB views are powering something you see in the UI by:

    - Right clicking the element.
    - Selecting "Inspect Element".
    - Looking for the `<!--XRAY START ...-->` comment above the element you've selected.

4. Figure out the full I18N translation key of any string on the page by adding `?show_locales=true` to the URL.

5. Use `bin/resolve` to figure out where framework or theme things are coming from and eject them if you need to customize something locally:

    ```
    $ bin/resolve Users::Base
    $ bin/resolve en.account.teams.show.header --open
    $ bin/resolve shared/box --open --eject
    ```

    Also, for inputs that can't be provided on the shell, there's an interactive mode where you can paste them:

    ```
    $ bin/resolve --interactive --eject --open
    ```

    And then paste any input, e.g.:

    ```
    <!--XRAY START 73 /Users/andrewculver/.rbenv/versions/3.1.1/lib/ruby/gems/3.1.0/gems/bullet_train-themes-light-1.0.10/app/views/themes/light/commentary/_box.html.erb-->
    ```
