#!/usr/bin/env bash

# exit on error
set -o errexit

while [ $# -gt 0 ] ; do
  case $1 in
    -s | --skip-migrations) SKIP_MIGRATE=true ;;
  esac
  shift
done

bundle install
bundle exec rails assets:precompile
bundle exec rails assets:clean
[[ $SKIP_MIGRATE == true ]] || bundle exec rails db:migrate
