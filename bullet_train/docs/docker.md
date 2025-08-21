# Using Docker with Bullet Train

We publish a number of pre-built Docker images, and we include a couple of `Dockerfile`s in
new (and upgraded) Bullet Train projects to help you get started.


## Pre-built Images

The images that we publish are layered to give us flexibility in how final images are produced.

* `bullet_train/base` - This is the most basic image, and it contains only _runtime_ dependencies
  that are needed for any/all reasonable use of a Bullet Train app. It contains things like `ruby`,
  a postgres client, and image manipulation libraries.
* `bullet_train/build` - This image builds upon `base` and included dependencies needed to build the
  app, but not to run it. Specifically it adds `node` which is required for building assets, but
  is not needed at runtime.
* `bullet_train/dev` - This image starts with `build` and adds dependencies that are needed in
  development mode, but that aren't needed in production.
* `bullet_train` - This image contains the full starter repo and is ready to run. You generally
  won't use this image, but if you wanted to give Bullet Train a quick test run it might be useful.

The `Dockerfile`s for these building-block images are in the [`dockerfiles` directory of the `core` repo.](https://github.com/bullet-train-co/bullet_train-core/tree/main/dockerfiles)

These images are versioned along with the gems, and they're built and published as part of our release process.

You can find the packages here: <https://github.com/orgs/bullet-train-co/packages>

You can install one of the images directly by doing something like this:

```
docker pull ghcr.io/bullet-train-co/bullet_train/base:1.27.0
```

And in a `Dockerfile` you can do this:

```
FROM ghcr.io/bullet-train-co/bullet_train/base:1.27.0
```

## Application Images

We include two `Dockerfile`s in the starter repo:

* `Dockerfile` is intended for building production images. Out of the box it should produce an image that is ready
  to deploy based on the current version of your app.
* `dev.Dockerfile` is intended to be run locally.

## `Dockerfile`

The main `Dockerfile` in a Bulle Train app is a two-stage file that's intented to produce a production-ready image.

The first stage is based on `bullet_train/build`. In this stage there is a block where you can install any native
**built-time** dependencies needed by your app. (Most apps probably won't need to install anything in this stage.)

The second stage is based on `bullet_train/base` and is intended to be the smallest possible image that can be
shipped to production. In this stage there is a block where you can install any custom **runtime** dependencies you need.

## `dev.Dockerfile`

`dev.Dockerfile` is intended to be used for running your app locally within Docker. This file uses `bullet_train/dev` as
the base image and gives you a block where you can install any runtime and development dependencies.

This file assumes that the local copy of the application will be mounted into the image. The convenience scripts below handle
that for you, and then your local changes will be reflected into the Docker image immediately.

To make easy use of `dev.Dockerfile` we've included a number of convenience scripts in `bin/docker-dev`

```
bin/docker-dev/
├── build - Build the image. Usually only needed after changing dependencies in `dev.Dockerfile`.
├── console - Run `rails console` inside Docker.
├── create - Create your development application container.
├── destroy - Destroy the development application container and image.
├── entrypoint - Used by `dev.Dockerfile` to start the rails server in your container.
├── shell - Get a bash shell inside your development application container.
├── start - Launch your development application container.
└── stop - Stop your development application container.
```

To get started with `dev.Dockerfile` you'd typically do this sequence:

```
bin/docker-dev/build
bin/docker-dev/create
bin/docker-dev/start
```

By default `bullet_train/dev` and `dev.Dockerfile` use the `host.docker.internal` virtual
host to allow the app to connect to postgres and redis running on the host machine.

In the future we plan to add a Docker Compose configuration that will allow you to run
postgres and redis in their own containers.


