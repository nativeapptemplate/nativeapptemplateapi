# bin/rails db:prepare (bin/docker-entrypoint) loads this file only when it has
# just created the schema: the first deploy, or a demo database that was reset.
# Production then gets the rows the app cannot run without (roles, permissions,
# app/privacy/terms versions; no users). Later deploys don't load it, so values
# an admin changed in /madmin stay. Development and test load their own
# db/fixtures with bin/rails db:seed_fu and the test setup.
SeedFu.seed([Rails.root.join("db/fixtures/production").to_s]) if Rails.env.production?
