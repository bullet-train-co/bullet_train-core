# syntax=docker/dockerfile:1
# check=error=true

#######################################################################################################
#
# This is the `dev` Dockerfile which we use to produce the `bullet_train/dev` image.
# Here we install development tools that are useful to have when running the project locally.
#
# This image is intended as a buiding block for other images and isn't really intended to be used directly.
#
# We use a GitHub Actions workflow (`.github/workflows/docker.yml`) to build this, and other images
# as a part of the release process.
#
#######################################################################################################
#
# Build this image fro the top level of the core repo:
# docker build -t bullet_train/dev -f dockerfiles/dev.Dockerfile --build-arg BULLET_TRAIN_VERSION=$(grep VERSION bullet_train/lib/bullet_train/version.rb | cut -d '"' -f 2) .
#
# Sometimes it's handy to get long output and skip the cache:
# docker build -t bullet_train/dev -f dockerfiles/dev.Dockerfile --build-arg BULLET_TRAIN_VERSION=$(grep VERSION bullet_train/lib/bullet_train/version.rb | cut -d '"' -f 2) . --no-cache --progress=plain
#
# You can then get a console to see what's on the dev image by doing:
# docker run -it bullet_train/dev /bin/bash
#
# For local testing you may want to pass a FROM_IMAGE build arg to use a locally build verison of the build image instead of a published one:
# docker build -t bullet_train/dev -f dockerfiles/dev.Dockerfile --build-arg BULLET_TRAIN_VERSION=$(grep VERSION bullet_train/lib/bullet_train/version.rb | cut -d '"' -f 2) --build-arg FROM_IMAGE=bullet_train/build .
#
# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html
#
#######################################################################################################

ARG BULLET_TRAIN_VERSION=fake.version
ARG FROM_IMAGE=ghcr.io/bullet-train-co/bullet_train/build:$BULLET_TRAIN_VERSION
FROM $FROM_IMAGE AS build

# Setup development environment vars
ENV RAILS_ENV="development" \
    BUNDLE_DEPLOYMENT="0" \
    BUNDLE_WITHOUT="" \
    REDIS_URL="redis://host.docker.internal:6379/1" \ 
    BINDING=0.0.0.0 \
    DATABASE_HOST=host.docker.internal \
    DATABASE_PORT=5432

# Install packages needed for development/test
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    graphviz \
    && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives
