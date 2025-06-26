# syntax=docker/dockerfile:1
# check=error=true

# Build this image:
# docker build -t bullet_train/build -f dockerfiles/build.Dockerfile --build-arg BULLET_TRAIN_VERSION=$(grep VERSION bullet_train/lib/bullet_train/version.rb | cut -d '"' -f 2) --build-arg NODE_VERSION=$(cat .nvmrc) --build-arg NODE_MAJOR_VERSION=$(cat .nvmrc | cut -d '.' -f 1) .

# Sometimes it's handy to get long output and skip the cache:
# docker build -t bullet_train/build -f dockerfiles/build.Dockerfile --build-arg BULLET_TRAIN_VERSION=$(grep VERSION bullet_train/lib/bullet_train/version.rb | cut -d '"' -f 2) --build-arg NODE_VERSION=$(cat .nvmrc) --build-arg NODE_MAJOR_VERSION=$(cat .nvmrc | cut -d '.' -f 1) . --no-cache --progress=plain

# You can then get a console to see what's on the build image by doing:
# docker run -it bullet_train/build /bin/bash

# For local testing you may want to pass a FROM_IMAGE build arg to use a locally build verison of the base image instead of a published one:
# docker build -t bullet_train/build -f dockerfiles/build.Dockerfile --build-arg BULLET_TRAIN_VERSION=$(grep VERSION bullet_train/lib/bullet_train/version.rb | cut -d '"' -f 2) --build-arg NODE_VERSION=$(cat .nvmrc) --build-arg NODE_MAJOR_VERSION=$(cat .nvmrc | cut -d '.' -f 1)  --build-arg FROM_IMAGE=bullet_train/base .

# BULLET_TRAIN_VERSION must be passed in as an ENV var. The GitHub Actions workflow that uses this file
# will take care of it for building the official images.
#######################################################################################################
ARG BULLET_TRAIN_VERSION=fake.version
ARG FROM_IMAGE=ghcr.io/bullet-train-co/bullet_train/base:$BULLET_TRAIN_VERSION
FROM $FROM_IMAGE AS base

ARG NODE_VERSION=fake.version
ARG NODE_MAJOR_VERSION=fake

# Ensure that apt-get doesn't try to run interactive configuration of installed packages
ENV DEBIAN_FRONTEND="noninteractive" \
    COREPACK_ENABLE_DOWNLOAD_PROMPT=0

# TODO: Is this the best way to install node?
# Prepare node and yarn for installation via apt-get
RUN curl -fsSL https://deb.nodesource.com/setup_$NODE_MAJOR_VERSION.x | bash -

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    libpq-dev \
    libyaml-dev \
    nodejs=$NODE_VERSION-1nodesource1 \
    pkg-config  \
    && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Enable corepack
RUN corepack enable
