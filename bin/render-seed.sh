#!/usr/bin/env bash

# exit on error
set -o errexit

if [[ "${IS_PULL_REQUEST}" == "true" ]]; then
  echo "IS_PULL_REQUEST is set. Setting staging environment variables and starting server."
  export RAILS_ENV=staging
  export RACK_ENV=staging
  export RAILS_MASTER_KEY=${STAGING_RAILS_MASTER_KEY}
  bundle exec rails db:seed_fu RAILS_ENV=staging
else
  echo "IS_PULL_REQUEST is not set or is set to false. Setting production environment variables and starting server."
  echo "Don't seed in production!"
fi
