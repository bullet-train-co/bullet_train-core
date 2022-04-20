# Publishing a Release to Both the Gem and the NPM module

Since this package is publishing both as a gem and as an npm module, there are a few steps to follow for local development and for release. We'll make these steps more automated in time.

## Local JavaScript Development

From this repo's directory:

```bash
# install dependencies
$ yarn

# prepare for having a symbolic link to this directory
$ yarn link 

# build and update as you work on the javascript
$ yarn build --watch
```

From the directory of the project including this package:

```bash
# create a symbolic link in node_modules/ to this package
yarn link <name in package.json>
```

Running `yarn` again from your project's directory will revert back to the published version of the package on npm.

Note: [Because of a weird behavior in how `yarn link` works](https://github.com/yarnpkg/yarn/issues/2914), you might have to make sure the project including this package includes a few of this package's dependencies (see `package.json` "dependencies" section). We'll be working on a better system.

## Release

1. Publish the gem with a new version number
2. Copy the version number in package.json
3. run `yarn build`. This will prepare the different javascript outputs
4. run `yarn pack`. This will create a new `.tgz` file for the new version
5. run `yarn publish <tgz filename> --new-version <version number in package.json>`
6. remove the `*.tgz` file