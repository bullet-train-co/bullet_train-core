# syntax=docker/dockerfile:1
# check=error=true

# If you have the core repo symlinked into your starter repo dir, you can run this from the starter repo:
# docker build -t bullet_train/build -f core/dockerfiles/Dockerfile.build --build-arg BULLET_TRAIN_VERSION=x.x.x .
#
# Sometimes it's handy to get long output and skip the cache:
# docker build -t bullet_train/build -f core/dockerfiles/Dockerfile.build --build-arg BULLET_TRAIN_VERSION=1.23.0 . --no-cache --progress=plain
#
# You can then get a console to see what's on the build image by doing:
# docker run -it bullet_train/build /bin/bash

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

#######################################################################################################
ARG BULLET_TRAIN_VERSION=fake.version
FROM ghcr.io/bullet-train-co/bullet_train/base:$BULLET_TRAIN_VERSION AS base

# Ensure that apt-get doesn't try to run interactive configuration of installed packages
ENV DEBIAN_FRONTEND="noninteractive"

# TODO: Is this the best way to install node and yarn?
# Prepare node and yarn for installation via apt-get
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# Install packages needed to build gems
# TODO: Do we need ffmpeg?
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    libpq-dev \
    libyaml-dev \
    pkg-config  \
    nodejs \
    # yarn \
    # ffmpeg \
    && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Enable corepack
RUN corepack enable

# Install application gems
#COPY Gemfile Gemfile.lock .ruby-version package.json yarn.lock ./

#RUN bundle install && \
    #rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    #bundle exec bootsnap precompile --gemfile && \
    #yarn install
