# Installing Bullet-Train Themes on Jumpstart PRO Projects

Bullet Train themes can be installed on Jumpstart PRO projects, giving you native `erb` partials and Hotwire-powered UI components.

Like Jumpstart PRO, Bullet Train themes are built using `tailwindcss` and use `esbuild` and `postcss` for JavaScript and style sheets.

To get a quick sense of the UI components, we encourage you to spin up a Bullet Train project and navigate through the screens to create a "Creative Concept" and "Tangible Thing" resources.

Note: we also have [instructions for installing themes on other Rails projects](on-other-rails-projects.md).

## Installation Instructions

### Add the theme gem

These instructions assume you're installing the `Light` theme bundled with Bullet Train.

```
$ bundle add bullet_train-themes-light
```

Or add the following to your `Gemfile`:

```
gem "bullet_train-themes-light"
```

And then run:

```
$ bundle install
```

### Add `npm` packages

The `Light` theme requires the following npm packages to be installed

```
$ yarn add @bullet-train/bullet-train @bullet-train/fields autoprefixer @rails/actiontext
```

Update your `app/javascript/controllers/index.js` with the following lines:

```js
import { controllerDefinitions as bulletTrainControllers } from "@bullet-train/bullet-train"
import { controllerDefinitions as bulletTrainFieldControllers } from "@bullet-train/fields"

application.load(bulletTrainControllers)
application.load(bulletTrainFieldControllers)
```

**(This should be automated by a rake task)**

### Add `bin/theme` and `bin/link` bin stubs

**(This should be automated by a rake task)**

### Update `tailwind.config.js`

Replace with these contents:

**(This should be automated via a rake task, merged with AI if there's an existing esbuild file)**

**(This is a merged tailwind config we'll need to manually maintain from this point on)**

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

**(This should be automated via a rake task)**

```json
"build:css": "bin/link; THEME=\"light\" tailwindcss --postcss --minify -c ./tailwind.config.js -i ./app/assets/stylesheets/application.tailwind.css -o ./app/assets/builds/application.light.css",
```

### Import the Theme Style Sheet

**(This should be automated by a rake task)**

To your application.tailwind.css file, add the following line:

```css
@import "$ThemeStylesheetsDir/light/application.css";
```

### Add Themify Icons

(This should be imported via the npm package automatically)

### Update `esbuild.config.js`

Replace it with these contents.

**(This should be automated via a rake task, merged with AI if there's an existing esbuild file)**

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