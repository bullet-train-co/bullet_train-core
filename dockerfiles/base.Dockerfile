# syntax=docker/dockerfile:1
# check=error=true

# Build this image fro the top level of the core repo:
# docker build -t bullet_train/base -f dockerfiles/base.Dockerfile --build-arg RUBY_VERSION=$(cat .ruby-version) .

# You can then get a console to see what's on the build image by doing:
# docker run -it bullet_train/base /bin/bash

# RUBY_VERSION must be passed in as an ENV var. The GitHub Actions workflow that uses this file
# will take care of it for building the official images.
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
