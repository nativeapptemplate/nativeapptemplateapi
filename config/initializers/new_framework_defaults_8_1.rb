# Be sure to restart your server when you modify this file.
#
# This file eases your Rails 8.1 framework defaults upgrade.
#
# Uncomment each configuration one by one to switch to the new default.
# Once your application is ready to run with all new defaults, you can remove
# this file and set the `config.load_defaults` to `8.1`.
#
# Read the Guide for Upgrading Ruby on Rails for more info on each option.
# https://guides.rubyonrails.org/upgrading_ruby_on_rails.html

###
# Configure Active Support JSON encoding to not escape non-ASCII characters in JSON output.
#++
# Rails.application.config.active_support.escape_json_responses = false

###
# Configures `ActiveRecord::FinderMethods` to raise an error when the `order` clause
# doesn't include all columns from the `select` clause that are required for ordering.
#++
# Rails.application.config.active_record.raise_on_missing_required_finder_order_columns = true

###
# Configure Action Dispatch to raise an error when a path-relative redirect is attempted.
#++
# Rails.application.config.action_dispatch.action_on_path_relative_redirect = :raise

###
# Configure Action View to use the Ruby render tracker instead of the default.
#++
# Rails.application.config.action_view.render_tracker = :ruby

###
# Configure Action View to add autocomplete="off" to hidden fields.
#++
# Rails.application.config.action_view.remove_hidden_field_autocomplete = true
