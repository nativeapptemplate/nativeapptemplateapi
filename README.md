# NativeAppTemplate API

Welcome! To get started, clone the repository.

## Requirements

You'll need the following installed to run the template successfully:

* Ruby 3.3.5+
* Node.js v20.17+
* PostgreSQL 16+
* Libvips or Imagemagick - `brew install vips imagemagick`
* [Overmind](https://github.com/DarthSim/overmind) or Foreman - `brew install tmux overmind` or `gem install foreman` - helps run all your processes in development

If you use Homebrew, dependencies are listed in `Brewfile` so you can install them using:

```bash
brew bundle install --no-upgrade
```

Then you can start the database servers:

```bash
brew services start postgresql
brew services start redis
```

## Initial Setup

First, edit `config/database.yml` and change the database credentials for your server.

Run `bin/setup` to install Ruby and JavaScript dependencies and setup your database.

```bash
bin/setup
```

## Running NativeAppTemplate API

Replace the IP address `192.168.1.21` with your local machine’s IP address in `Procfile.dev` and `config/environments/development.rb`.

To run your application, you'll use the `bin/dev` command:

```bash
bin/dev
```

This starts up Overmind (or Foreman) running the processes defined in `Procfile.dev`. We've configured this to run the Rails server, CSS bundling, JS bundling and run the Sidekiq out of the box.

## Contributing

If you have an improvement you'd like to share, create a fork of the repository and send us a pull request.
