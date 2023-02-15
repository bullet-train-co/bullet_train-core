# Dealing with Indirection

## The Problem with Indirection

In software development, indirection is everywhere and takes many forms.

For example, in vanilla Rails development, you introduce a type of indirection when you extract a button label out of a view file and use the `t` helper to render the string from a translation YAML file. In the future, when another developer goes to update the button label, they will first open the view, they'll see `t(".submit")` and then have to reason a little bit about which translation file they need to open up in order to update that label.

Our goal in Bullet Train is to improve developer experience, not reduce it, so it was important that along with any instances of indirection we were introducing, we also included new tooling to ensure it was never a burden to developers. Thankfully, in practice we found that some of this new tooling improves even layers of indirection that have always been with us in Rails development.

## Figuring Out Class Locations

Most of Bullet Train's functionality is distributed via Ruby gems, not the starter template. As a result, the power of fuzzy searching in your IDE is more limited. For example, `app/controllers/account/users_controller.rb` includes its base functionality from a concern called `Account::Users::ControllerBase`. If you try to fuzzy search for it, you'll quickly find the module isn't included in your application repository. However, you can quickly figure out which Ruby gem is providing that concern and inspect it's source by running:

```
bin/resolve Account::Users::ControllerBase --open
```

If you need to modify behavior in these framework-provided classes or modules, see the documentation for [Overriding Framework Defaults](/docs/overriding.md).

## Solving Indirection in Views

### Resolving Partial Paths with `bin/resolve`

Even in vanilla Rails development, when you're looking at a view file, the path you see passed to a `render` call isn't the actual file name of the partial that will be rendered. This is even more true in Bullet Train where certain partial paths are [magically served from theme gems](/docs/themes.md).

`bin/resolve` makes it easy to figure out where where a partial is being served from:

```
bin/resolve shared/box
```

### Exposing Rendered Views with Annotated Views

If you're looking at a rendered view in the browser, it can be hard to know which file to open in order to make a change. To help, Bullet Train enables `config.action_view.annotate_rendered_view_with_filenames` by default, so you can right click on any element you see, select "Inspect Element", and you'll see comments in the HTML source telling you which file is powering a particular portion of the view, like this:

```
<!-- BEGIN /Users/andrewculver/.rbenv/versions/3.1.2/lib/ruby/gems/3.1.0/gems/bullet_train-themes-light-1.0.10/app/views/themes/light/workflow/_box.html.erb -->
```

If you want to customize files like this that you find annotated in your browser, you can use the `--interactive` flag to eject the file to your main application, or simply open it in your code editor.

```
> bin/resolve --interactive

OK, paste what you've got for us and hit <Return>!

<!-- BEGIN /Users/andrewculver/.rbenv/versions/3.1.2/lib/ruby/gems/3.1.0/gems/bullet_train-themes-light-1.0.10/app/views/themes/light/workflow/_box.html.erb -->

Absolute path:
  /Users/andrewculver/.rbenv/versions/3.1.2/lib/ruby/gems/3.1.0/gems/bullet_train-themes-light-1.0.10/app/views/themes/light/workflow/_box.html.erb

Package name:
  bullet_train-themes-light-1.0.10


Would you like to eject the file into the local project? (y/n)
n

Would you like to open `/Users/andrewculver/.rbenv/versions/3.1.2/lib/ruby/gems/3.1.0/gems/bullet_train-themes-light-1.0.10/app/views/themes/light/workflow/_box.html.erb`? (y/n)
y
```

You may also want to consider using `bin/hack`, which will clone the Bullet Train core packages to `local/bullet_train-core` within your main application's root directory. Running this command will also automatically link the packages to your main application and open bullet_train-core in the code editor for you, so you can start using the cloned repository and make changes to your main application right away.

To revert back to using the original gems, run `bin/hack --reset`. You can link up to your local packages at any time with `bin/hack --link`.

Note that in the example above, the view in question isn't actually coming from the application repository. Instead, it's being included from the `bullet_train-themes-light` package. For further instructions on how to customize it, see [Overriding Framework Defaults](/docs/overriding.md).

### Drilling Down on Translation Keys

Even in vanilla Rails applications, extracting strings from view files into I18n translation YAML files introduces a layer of indirection. Bullet Train tries to improve the resulting DX with a couple of tools that make it easier to figure out where a translation you see in your browser is coming from.

#### Show Translation Keys in the Browser with `?show_locales=true`

You can see the full translation key of any string on the page by adding `?show_locales=true` to the URL.

#### Log Translation Keys to the Console with `?log_locales=true`

You can also log all the translation keys for anything being rendered to the console by adding `?log_locales=true` to the request URL. This can make it easier to copy and paste translation keys for strings that are rendered in non-selectable UI elements.

#### Resolving Translation Keys with `bin/resolve`

Once you have the full I18n translation key, you can use `bin/resolve` to figure out which package and file it's coming from. At that point, if you need to customize it, you can also use the `--eject` option to copy the framework for customization in your local application:

```
bin/resolve en.account.onboarding.user_details.edit.header --eject --open
```
