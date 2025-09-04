#!/usr/bin/env bash
# Exit on error
set -o errexit

# Install gems (including deployment gems)
bundle install

# Pre-compile assets (using a swapfile for memory)
bundle exec rake assets:precompile
bundle exec rake assets:clean
bundle exec rake db:migrate
