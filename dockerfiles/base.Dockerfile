# syntax=docker/dockerfile:1
# check=error=true

#######################################################################################################
#
# This is the `base` Dockerfile which we use to produce the `bullet_train/base` image.
# Here we install runtime dependencies that are needed for any/all reasonable use of a Bullet Train app.
# Things like ruby, a postgres client, image manipulation libraries, etc.
#
# Things that we DO NOT install here:
# * development tools
# * testing tools
# * production specific dependencies
#
# This image is intended as a buiding block for other images and isn't really intended to be used directly.
#
# We use a GitHub Actions workflow (`.github/workflows/docker.yml`) to build this, and other images
# as a part of the release process.
#
#######################################################################################################
#
# Build this image from the top level of the core repo:
# docker build -t bullet_train/base -f dockerfiles/base.Dockerfile --build-arg RUBY_VERSION=$(cat .ruby-version) .
#
# You can then get a console to see what's on the build image by doing:
# docker run -it bullet_train/base /bin/bash
#
# RUBY_VERSION must be passed in as an ENV var. The GitHub Actions workflow that uses this file
# will take care of it for building the official images.
#
#######################################################################################################
ARG RUBY_VERSION=fake.version
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    libjemalloc2 \
    libvips \
    postgresql-client \
    && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# Add a user and group that will be used to run the app
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash
