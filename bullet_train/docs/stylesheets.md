# Style Sheets
Bullet Train's stock UI theme, called “Light”, is built to use `tailwindcss` extensively.

You'll notice that there are no local style sheets defined in new Bullet Train projects. If you look at the `light:build:css` script defined in `package.json`, you'll see how `tailwindcss` is run using the theme's own main style sheet as input.

There are two ways to update the styling of your app: either by modifying theme partials, or by allowing local CSS overrides.

## Modify Theme Partials

Since `tailwindcss` is used, most style changes are done by ejecting theme partials into a local copy, and modifying the Tailwind classes within their HTML.

You can eject only the theme files you wish to override or you can eject the whole UI theme for customization. You can find more information in the [indirection documentation](indirection) about using `bin/resolve` to find the theme partials to eject. Or see the [theme documentation](theme) for details on using the "Light" UI theme as a starting point for  creating your own.

## Allow Local CSS Overrides 

If you need to add your own custom CSS, override the custom non-tailwind classes found in the `light` theme (custom classes are still used sparingly), or to import CSS from a third-party component, there's a way to set up local CSS overrides.

You can use the following command to create a local version of the theme's main CSS file.

```
> rake bullet_train:themes:light:init_local_css
```

This will create a local version of `app/assets/stylesheets/light.tailwind.css` for modification. It imports `@tailwind` base styles, and the `light` theme files. You'll have full control by editing and modying this file, as it will take precedence over the version found in the theme's own gem.