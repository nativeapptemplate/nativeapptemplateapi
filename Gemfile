source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby file: ".ruby-version"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "7.1.5.1"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails", ">= 3.4.1"

# Use postgresql as the database for Active Record
gem "pg"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 6.0"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails", "~> 2.0.3"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails", "~> 1.0", ">= 1.0.2"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder", "~> 2.12"

# Use Redis adapter to run Action Cable in production
gem "redis", "~> 5.1"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.4.2", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.12"

# Security update
gem "nokogiri", ">= 1.12.5"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem "rack-cors"
gem "devise_token_auth", "~> 1.2", ">= 1.2.2"
gem "jsonapi-serializer"
gem "pundit"
gem "aasm"
# https://github.com/aasm/aasm
gem "after_commit_everywhere", "~> 1.4"
gem "config"
gem "sidekiq"
gem "acts_as_tenant"
gem "inline_svg", "~> 1.6"
gem "seed-fu", "~> 2.3"
gem "whenever", require: false
gem "madmin", github: "excid3/madmin"
gem "valid_email2"
gem "cssbundling-rails", "~> 1.4.0"
gem "jsbundling-rails", "~> 1.3.0"
gem "rack-attack"
# Fix LoadError: cannot load such file -- csv
gem "csv", "~> 3.3"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri windows]

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  gem "erb_lint", require: false

  gem "mailbin"

  # Optional debugging tools
  # gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  # gem "pry-rails"
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem "web-console", ">= 4.1.0"

  # A fully configurable and extendable Git hook manager
  gem "overcommit", require: false
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem "capybara", ">= 3.39"
  gem "selenium-webdriver", ">= 4.20.1"
  gem "webmock"
end

