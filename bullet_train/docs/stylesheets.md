# Style Sheets
Bullet Train's stock UI theme, called “Light”, is built to use `tailwindcss` extensively.

As such, there are two ways to update the styling of your app: either by modifying theme partials, or by adding your own custom CSS.

## Modify Theme Partials

Since `tailwindcss` is used, most style changes are done by ejecting theme partials into a local copy, and modifying the Tailwind classes within their HTML.

You can eject only the theme files you wish to override or you can eject the whole UI theme for customization. You can find more information in the [indirection documentation](indirection) about using `bin/resolve` to find the theme partials to eject. Or see the [themes documentation](themes) for details on using the "Light" UI theme as a starting point for creating your own.

## Add custom CSS 

If you need to add your own custom CSS, override the custom non-tailwind classes found in the `light` theme (custom classes are still used sparingly), or to import CSS from a third-party component, simply add to the `app/assets/stylesheets/application.custom.css` file.

You'll also have the ability to use Tailwind `@apply` directives.

For further modifications to the theme's style sheet (for example, to change the order in which tailwind styles are included), you can eject the theme's css by using the command `rake bullet_train:themes:light:eject_css`.