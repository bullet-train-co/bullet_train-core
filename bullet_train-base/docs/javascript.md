# JavaScript
Bullet Train leans into the use of [Stimulus](https://stimulus.hotwired.dev) for custom JavaScript. If you haven't read it previously, [the original introductory blog post for Stimulus from 2018](https://medium.com/signal-v-noise/stimulus-1-0-a-modest-javascript-framework-for-the-html-you-already-have-f04307009130) was groundbreaking in its time, and we still consider it required reading for understanding the philosophy of JavaScript in Bullet Train.

## Writing Custom JavaScript
The happy path for writing new custom JavaScript is to [write it as a Stimulus controller](https://stimulus.hotwired.dev/handbook/building-something-real) in `app/javascript/controllers` and invoke it by augmenting the HTML in your views. If you name the file `*_controller.js`, it will be automatically picked up and compiled as part of your application's JavaScript bundle.

## npm Packages
npm packages are managed by [Yarn](https://yarnpkg.com) and any required importing can be done in `app/javascript/application.js`.

## Compilation
Bullet Train uses [esbuild](https://esbuild.github.io) to compile all local JavaScript and npm package dependencies. If you haven't used esbuild before, it's blazing fast compared to older options like Webpack. Honestly, it makes JavaScript development and deployment in complex applications a joy again, in a way it hasn't been for years.

In development, the esbuild process that compiles JavaScript is defined as `yarn build` in `package.json`. This script also has an entry in `Procfile.dev`, so it runs automatically when you start your application with `bin/dev`, and when run in this context, it watches the filesystem and automatically recompiles anytime JavaScript files change on disk.

The resulting JavaScript bundle is output to the `app/assets/builds` directory where it is picked up by the traditional Rails asset pipeline. This directory is listed in `.gitignore`, so the compiled bundles are never committed to the repository.

## React, Vue.js, etc.
We're not against the use of front-end JavaScript frameworks in the specific contexts where they're the best tool for the job, but we solidly subscribe to the "heavy machinery" philosophy put forward in [that original Stimulus blog post](https://medium.com/signal-v-noise/stimulus-1-0-a-modest-javascript-framework-for-the-html-you-already-have-f04307009130), and have no interest in actually supporting them.
