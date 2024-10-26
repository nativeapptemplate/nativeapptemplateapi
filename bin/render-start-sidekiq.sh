#!/usr/bin/env bash

# exit on error
set -o errexit

if [[ "${IS_PULL_REQUEST}" == "true" ]]; then
  echo "Setting up sidekiq in staging mode"
  export RAILS_ENV=staging
  export RACK_ENV=staging
  export RAILS_MASTER_KEY=${STAGING_RAILS_MASTER_KEY}
  bundle exec sidekiq -e staging
else
  echo "Setting up sidekiq in production mode"
  export RAILS_ENV=production
  export RACK_ENV=production
  bundle exec sidekiq -e production
fi
