# JavaScript
Bullet Train leans into the use of [Stimulus](https://stimulus.hotwired.dev) for custom JavaScript. If you haven't read it previously, [the original introductory blog post for Stimulus from 2018](https://medium.com/signal-v-noise/stimulus-1-0-a-modest-javascript-framework-for-the-html-you-already-have-f04307009130) was groundbreaking in its time, and we still consider it required reading for understanding the philosophy of JavaScript in Bullet Train.

## Writing Custom JavaScript
The happy path for writing new custom JavaScript is to [write it as a Stimulus controller](https://stimulus.hotwired.dev/handbook/building-something-real) in `app/javascript/controllers` and invoke it by augmenting the HTML in your views. If you name the file `*_controller.js`, it will be automatically picked up and compiled as part of your application's JavaScript bundle. Be careful to [avoid adding scripts to the body of your pages (see below)](#avoid-scripts-in-the-body).

## Overriding BulletTrain Stimulus Controllers

If you need to slightly tweak the behavior of the built-in Bullet Train Stimulus controllers you can do it easily.

Let's say you want to alter the SuperSelectController.

First create a file at: `app/javascript/controllers/fields/super_select_controller.js`

And then update that controller to first `import` the BT controller that you want to override,
and then `export` a class that `extends` the controller that you just imported.

For example, this will make it so that the BT Super Select controller will log a line to the console
every time that `connect` is calle:

```javascript
import { SuperSelectController } from '@bullet-train/fields'

export default class extends SuperSelectController {
  connect() {
    console.log('super_select_controller connected')
    super.connect()
  }
}
```

## npm Packages
npm packages are managed by [Yarn](https://yarnpkg.com) and any required importing can be done in `app/javascript/application.js`.

## Compilation
Bullet Train uses [esbuild](https://esbuild.github.io) to compile all local JavaScript and npm package dependencies. If you haven't used esbuild before, it's blazing fast compared to older options like Webpack. Honestly, it makes JavaScript development and deployment in complex applications a joy again, in a way it hasn't been for years.

In development, the esbuild process that compiles JavaScript is defined as `yarn build` in `package.json`. This script also has an entry in `Procfile.dev`, so it runs automatically when you start your application with `bin/dev`, and when run in this context, it watches the filesystem and automatically recompiles anytime JavaScript files change on disk.

The resulting JavaScript bundle is output to the `app/assets/builds` directory where it is picked up by the traditional Rails asset pipeline. This directory is listed in `.gitignore`, so the compiled bundles are never committed to the repository.

## React, Vue.js, etc.
We're not against the use of front-end JavaScript frameworks in the specific contexts where they're the best tool for the job, but we solidly subscribe to the "heavy machinery" philosophy put forward in [that original Stimulus blog post](https://medium.com/signal-v-noise/stimulus-1-0-a-modest-javascript-framework-for-the-html-you-already-have-f04307009130), and have no interest in actually supporting them.

## Complex Screen Interactions

For more complex screen interactions, we do recommend using features of Hotwire's Turbo framework, Turbo Frames in particular.

Here are some important considerations:

### Avoid Morphing for Page Refreshes (It Breaks Form Fields)

We don't recommend using [Turbo's Morphing](https://turbo.hotwired.dev/handbook/page_refreshes) for refreshing whole screens, especially not when the screen contains form fields. That's because Turbo's Morphing works by comparing and modifying the DOM in a way that breaks JavaScript-created elements. Bullet Train's field partials, however, use third-party librairies, like those created by our `super_select`, our `date_field`, and even the Trix rich-text editor, which create their own elements via JavaScript. Use Turbo's Morphing sparingly.

### Reactive Page Updates with CableReady::Updatable

Bullet Train's answer to reactive page updates is a lightweight library called [CableReady::Updatable](https://cableready.stimulusreflex.com/guide/updatable.html). Rather than refreshing whole pages, it defines specific page regions that update themselves on model changes, across browser sessions. Look throughout your scaffolded `index` and `show` views for `cable_ready_updates_for` and in your models for the `enable_cable_ready_updates: true` option on `has_many` associations. By default, forms are not defined as updatable regions using CableReady::Updatable, for the same reasons explained above.

### Dynamic Forms

For creating dynamically-updated forms, Bullet Train introduces two powerful new patterns: the [_Dependent Fields Pattern_ and the _Dependent Fields Frame_](/docs/field-partials/dynamic-forms-dependent-fields.md). If you use the `address_field` partial, you'll see the pattern in action: changing the country will update the state and zip code fields. You can use these patterns to create complex, dynamically-updated forms.

## Avoid Scripts in the Body

If you experience slow Turbo interactions, check for script tags in the body of your pages. Following [Turbo's documentation](https://turbo.hotwired.dev/handbook/building#working-with-script-elements):

❌ Don't place scripts in the body:

```html
<body>
<script src="third-party-tracker.js"></script>
</body>
```

✅ Instead, place them in the head with the `defer` attribute:

```html
<head>
<script src="third-party-tracker.js" defer></script>
</head>
```
