# Installing Bullet-Train Themes on Jumpstart PRO Projects

Bullet Train themes can be installed on Jumpstart PRO projects, giving you native `erb` partials and Hotwire-powered UI components.

Like Jumpstart PRO, Bullet Train themes are built using `tailwindcss` and use `esbuild` and `postcss` for JavaScript and style sheets.

To get a quick sense of the UI components, we encourage you to spin up a Bullet Train project and navigate through the screens to create a "Creative Concept" and "Tangible Thing" resources.

In addition to providing a nice set of UI components, you'll get access to [`nice_partials`](https://github.com/bullet-train-co/nice_partials), Bullet-Train's own lightweight answer for creating `erb` partials with ad-hoc named content areas, which we think is just the right amount of magic for making `erb`-based components.

Note: we also have [instructions for installing themes on other Rails projects](on-other-rails-projects.md).

**Contents:**

1. Installation Instructions
2. Optional Configurations for switching colors, theme gems
3. Using Locales for fields on new models
4. Partials that require special instructions, exclusions
5. Modifying ejected partials

## 1. Installation Instructions

### Add the theme gem

These instructions assume you're installing the `Light` theme bundled with Bullet Train.

```
bundle add bullet_train-themes-light
```

Or add the following to your `Gemfile`:

```
gem "bullet_train-themes-light"
```

And then run:

```
bundle install
```

### Add `npm` packages

The `Light` theme requires the following npm packages to be installed

```
yarn add @bullet-train/bullet-train @bullet-train/fields autoprefixer @rails/actiontext
```

Update your `app/javascript/controllers/index.js` with the following lines:

```js
import { controllerDefinitions as bulletTrainControllers } from "@bullet-train/bullet-train"
import { controllerDefinitions as bulletTrainFieldControllers } from "@bullet-train/fields"

application.load(bulletTrainControllers)
application.load(bulletTrainFieldControllers)
```

### Add `bin/theme` and `bin/link` bin stubs

```
curl -L "https://raw.githubusercontent.com/bullet-train-co/bullet_train/main/bin/theme" -o bin/theme
curl -L "https://raw.githubusercontent.com/bullet-train-co/bullet_train/main/bin/link" -o bin/link
chmod +x bin/theme bin/link
```

### Update `esbuild.config.mjs`

Replace it with these contents.

```js
#!/usr/bin/env node

// Esbuild is configured with 3 modes:
//
// `yarn build` - Build JavaScript and exit
// `yarn build --watch` - Rebuild JavaScript on change
// `yarn build --reload` - Reloads page when views, JavaScript, or stylesheets change. Requires a PORT to listen on. Defaults to 3200 but can be specified with PORT env var
//
// Minify is enabled when "RAILS_ENV=production"
// Sourcemaps are enabled in non-production environments

import * as esbuild from "esbuild"
import path from "path"
import rails from "esbuild-rails"
import chokidar from "chokidar"
import http from "http"
import { setTimeout } from "timers/promises"

const clients = []
const entryPoints = [
  "application.js",
  "administrate.js"
]
const watchDirectories = [
  "./app/javascript/**/*.js",
  "./app/views/**/*.html.erb",
  "./app/assets/builds/**/*.css", // Wait for cssbundling changes
  "./config/locales/**/*.yml",
]
const config = {
  absWorkingDir: path.join(process.cwd(), "app/javascript"),
  bundle: true,
  entryPoints: entryPoints,
  minify: process.env.RAILS_ENV == "production",
  outdir: path.join(process.cwd(), "app/assets/builds"),
  plugins: [rails()],
  sourcemap: process.env.RAILS_ENV != "production",
  define: {
    global: "window"
  },
  loader: {
    ".png": "file",
    ".jpg": "file",
    ".svg": "file",
    ".woff": "file",
    ".woff2": "file",
    ".ttf": "file",
    ".eot": "file",
  }
}

async function buildAndReload() {
  // Foreman & Overmind assign a separate PORT for each process
  const port = parseInt(process.env.PORT || 3200)
  console.log(`Esbuild is listening on port ${port}`)
  const context = await esbuild.context({
    ...config,
    banner: {
      js: ` (() => new EventSource("http://localhost:${port}").onmessage = () => location.reload())();`,
    }
  })

  // Reload uses an HTTP server as an even stream to reload the browser
  http
    .createServer((req, res) => {
      return clients.push(
        res.writeHead(200, {
          "Content-Type": "text/event-stream",
          "Cache-Control": "no-cache",
          "Access-Control-Allow-Origin": "*",
          Connection: "keep-alive",
        })
      )
    })
    .listen(port)

  await context.rebuild()
  console.log("[reload] initial build succeeded")

  let ready = false
  chokidar
    .watch(watchDirectories)
    .on("ready", () => {
      console.log("[reload] ready")
      ready = true
    })
    .on("all", async (event, path) => {
      if (ready === false)  return

      if (path.includes("javascript")) {
        try {
          await setTimeout(20)
          await context.rebuild()
          console.log("[reload] build succeeded")
        } catch (error) {
          console.error("[reload] build failed", error)
        }
      }
      clients.forEach((res) => res.write("data: update\n\n"))
      clients.length = 0
    })
}

if (process.argv.includes("--reload")) {
  buildAndReload()
} else if (process.argv.includes("--watch")) {
  let context = await esbuild.context({...config, logLevel: 'info'})
  context.watch()
} else {
  esbuild.build(config)
}
```

### Update `tailwind.config.js`

Replace with these contents, which merge the Bullet Train-specific tailwind configs with those of Jumpstart PRO.

_Note: After this step, you might get an error on build about a missing `process.env.THEME`. Follow with the next step to fix this error._

```js
const path = require('path');
const { execSync } = require("child_process");
const glob  = require('glob').sync

if (!process.env.THEME) {
  throw "tailwind.config.js: missing process.env.THEME"
  process.exit(1)
}
  
const themeConfigFile = execSync(`bundle exec bin/theme tailwind-config ${process.env.THEME}`).toString().trim()
let themeConfig = require(themeConfigFile)

const colors = require('tailwindcss/colors')
const defaultTheme = require('tailwindcss/defaultTheme')

themeConfig.darkMode = 'class'

themeConfig.plugins.push(require('@tailwindcss/aspect-ratio'))

themeConfig.content = [
  ...new Set([
    ...themeConfig.content,
    './app/components/**/*.rb',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.erb',
    './app/views/**/*.haml',
    './app/views/**/*.slim',
    './lib/jumpstart/app/views/**/*.erb',
    './lib/jumpstart/app/helpers/**/*.rb'
  ])
]

themeConfig.theme.extend.colors = {
  ...themeConfig.theme.extend.colors,
  primary: colors.blue,
  secondary: colors.emerald,
  tertiary: colors.gray,
  danger: colors.red,
  gray: colors.neutral,
  "code-400": "#fefcf9",
  "code-600": "#3c455b",
}

themeConfig.theme.extend.fontFamily = {
  ...themeConfig.theme.extend.fontFamily,
  sans: ['Inter', ...defaultTheme.fontFamily.sans],
}

module.exports = themeConfig
```

### Update `build:css` in `package.json`

In `package.json`, add or replace the `build:css` entry under `scripts` with:

```json
"build:css": "bin/link; THEME=\"light\" tailwindcss --postcss --minify -c ./tailwind.config.js -i ./app/assets/stylesheets/application.tailwind.css -o ./app/assets/builds/application.light.css",
```

### Import the Theme Style Sheet

To your `application.tailwind.css` file, add the following line:

```css
@import "$ThemeStylesheetsDir/light/application.css";
```

### Add Themify Icons and jQuery (for now)

Note: jQuery is needed for some of our components, but defining `window.$` won't be required soon. See PR https://github.com/bullet-train-co/bullet_train-core/pull/765

```
yarn add @icon/themify-icons jquery
```

To your `application.js`, add the following line:

```js
import "jquery" from jquery
window.jQuery = jquery
window.$ = jquery

require("@icon/themify-icons/themify-icons.css")
```

### Add Locale Strings

Add these to your `config/locales/en.yml` under `en:`

```yml
  date:
    formats:
      date_field: "%m/%d/%Y"
      date_and_time_field: "%m/%d/%Y %l:%M %p"
      date_controller: "MM/DD/YYYY"
  time:
    am: AM
    pm: PM
    formats:
      date_field: "%m/%d/%Y"
      date_and_time_field: "%m/%d/%Y %l:%M %p"
      date_controller: "MM/DD/YYYY h:mm A"
  daterangepicker:
    firstDay: 1
    separator: " - "
    applyLabel: "Apply"
    cancelLabel: "Cancel"
    fromLabel: "From"
    toLabel: "To"
    customRangeLabel: "Custom"
    weekLabel: "W"
    daysOfWeek:
    - "Su"
    - "Mo"
    - "Tu"
    - "We"
    - "Th"
    - "Fr"
    - "Sa"
    monthNames:
    - "January"
    - "February"
    - "March"
    - "April"
    - "May"
    - "June"
    - "July"
    - "August"
    - "September"
    - "October"
    - "November"
    - "December"
  date_range_controller:
    today: Today
    yesterday: yesterday
    last7Days: Last 7 Days
    last30Days: Last 30 Days
    thisMonth: This Month
    lastMonth: Last Month
  global:
    buttons:
      other: Other
      cancel: Cancel
    bulk_select:
      all: All
```

### Disable `display: block` on `label` elements

In `app/assets/stylesheets/components/forms.css`, find the line:

```css
@apply block text-sm font-medium leading-5 text-gray-700 mb-1;
```

And remove the `block` token:

```css
@apply text-sm font-medium leading-5 text-gray-700 mb-1;
```

## 2. Optional Configurations for switching colors, theme gems

### For Setting the Active Color

```
curl -L "https://raw.githubusercontent.com/bullet-train-co/bullet_train/main/initializers/theme.rb" -o initializers/theme.rb
```

Add the following classes to your `html` tag for your layout:

```erb
<html class="theme-<%= BulletTrain::Themes::Light.color %> <%= "theme-secondary-#{BulletTrain::Themes::Light.secondary_color}" if BulletTrain::Themes::Light.secondary_color %>"
```

### For Switching Between Installed Themes

If you'd like to create your own theme but would still like to build on top of `:light`, you'll need to have both gems installed and you'll be able to switch the current theme this way.

Define `current_theme` in `app/helpers/application_helper.rb`

```
module ApplicationHelper
  def current_theme
    :light
  end
end
```

To change to use a different theme:

1. Change the value returned by `current_theme` to the new theme name
2. Change the name of the `THEME` env var defined in `build:css` in `package.json`

## 3. Using Locales for fields on new models

The theme's field partials work best with locale strings that are defined for the model you're creating.

Example: you've created a Project model. Here we'll create a `projects.en.yml`

1. Run `curl -L "https://raw.githubusercontent.com/bullet-train-co/bullet_train-core/main/bullet_train-super_scaffolding/config/locales/en/scaffolding/completely_concrete/tangible_things.en.yml" -o config/locales/projects.en.yml`
2. Search and replace `projects.en.yml` for `scaffolding/completely_concrete/tangible_things`, `Tangible Things`, `Tangible Thing`, `tangible_things` and `tangible_thing`. Replace with `projects`, `Projects`, `Project`, `projects` and `project` respectively.
3. Remove strings you won't be using. In particular, look for comments with "skip" or "scaffolding".

Some fields use locale strings to drive their `options`. In the `tangible_things.en.yml` template file, look for `super_select_value`, `multiple_option_values` and others.

You'll notice `&` and `*` symbols prefixing some special keys in the `yml` file. Those are anchors and aliases and they help you reduce repetition in your locale strings.

To learn more about how these locales are generated in Bullet Train, see the documentation on [Bullet Train's Super Scaffolding](/docs/super-scaffolding.md)

## 4. Partials that require special instructions, exclusions

### For using boolean-type fields (options, buttons)

In `ApplicationController`, add this:

```ruby
include Fields::ControllerSupport
```

### For the file_field partial

```ruby
# in the model
has_one_attached :file_field_value
after_validation :remove_file_field_value, if: :file_field_value_removal?
attr_accessor :file_field_value_removal
def file_field_value_removal?
def remove_file_field_value
```

```ruby
# in the controller's strong_params
:file_field_value,
:file_field_value_removal,
```

### For `image`, `active_storage_image`

See [`account/users_helper` in BT core repo](https://github.com/bullet-train-co/bullet_train-core/blob/main/bullet_train/app/helpers/account/users_helper.rb) for implementing `photo_url_for_active_storage_attachment`

## 5. Modifying ejected partials

### For ejecting a theme partial and modifying it

We recommend firing up a Bullet-Train project and using its `bin/resolve` (see docs on [Indirection](indirection)) to get a copy of the partial field locally to modify.