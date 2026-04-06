# NativeAppTemplate API

A [Rails 8.1](https://rubyonrails.org/) API backend for NativeAppTemplate iOS/Android mobile applications. It's a multi-tenant SaaS application with token-based authentication, role-based authorization, and RESTful API endpoints.

For more information, visit [nativeapptemplate.com](https://nativeapptemplate.com).

## Related Repositories

### Paid Clients
- [NativeAppTemplate-iOS](https://github.com/nativeapptemplate/NativeAppTemplate-iOS)
- [NativeAppTemplate-Android](https://github.com/nativeapptemplate/NativeAppTemplate-Android)

### Free Clients
- [NativeAppTemplate-Free-iOS](https://github.com/nativeapptemplate/NativeAppTemplate-Free-iOS)
- [NativeAppTemplate-Free-Android](https://github.com/nativeapptemplate/NativeAppTemplate-Free-Android)

## Requirements

You'll need the following installed to run the template successfully:

* Ruby 4.0.2+
* PostgreSQL 16+
* Libvips - `brew install vips`
* [Overmind](https://github.com/DarthSim/overmind) or Foreman - `brew install tmux overmind` or `gem install foreman` - helps run all your processes in development

If you use Homebrew, dependencies are listed in `Brewfile` so you can install them using:

```bash
brew bundle install --no-upgrade
```

Then you can start the database servers:

```bash
brew services start postgresql
```

## Initial Setup

First, edit `config/database.yml` and change the database credentials for your server.

Run `bin/setup` to install Ruby and JavaScript dependencies and setup your database and seed initial data to the database.

```bash
bin/setup
```

## Running NativeAppTemplate API on localhost

Replace the IP address `192.168.1.21` with your localhost IP address in `Procfile.dev` and `config/environments/development.rb`.

To run your application, you'll use the `bin/dev` command:

```bash
bin/dev
```

This starts up Overmind (or Foreman) running the processes defined in `Procfile.dev`. We've configured this to run the Rails server out of the box.

## Contributing

If you have an improvement you'd like to share, create a fork of the repository and send us a pull request.
