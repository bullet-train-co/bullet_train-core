# Style Sheets
Bullet Train's stock UI theme, called “Light”, is built to use `tailwindcss` extensively, where most of the styling is defined within the `.html.erb` theme partials.

As such, there are two ways to update the styling of your app: either by modifying theme partials, or by adding your own custom CSS.

## Modify Theme Partials

Since `tailwindcss` is used, most style changes are done by ejecting theme partials into your app's `app/views` directory, and modifying the Tailwind classes within the `.html.erb` templates.

You can eject only the theme files you wish to override or you can eject the whole UI theme for customization. You can find more information in the [indirection documentation](indirection) about using `bin/resolve` to find the theme partials to eject. Or see the [themes documentation](themes) for details on using the "Light" UI theme as a starting point for creating your own.

## Add custom CSS 

To add your own custom CSS, add to the `app/assets/stylesheets/application.css` file found in your app. In this file, you'll be able to use Tailwind `@apply` directives and add `@import` statements to include the CSS from third-party `npm` packages.

For further modifications to the theme's style sheet (for example, to change the order in which base Tailwind stylesheets are included), you can eject the theme's css by using the command `rake bullet_train:themes:light:eject_css`.

## Using Custom Fonts

For information on customizing fonts in your application, see the [Customizing Fonts](/docs/themes.md#customizing-fonts) section in the Themes documentation.
