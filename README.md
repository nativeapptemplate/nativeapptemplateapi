# NativeAppTemplate API

[![Mentioned in Awesome Rails](https://awesome.re/mentioned-badge.svg)](https://github.com/gramantin/awesome-rails#startersboilerplates)

A [Rails 8.1](https://rubyonrails.org/) API backend for NativeAppTemplate iOS/Android mobile applications. It's a multi-tenant SaaS application with token-based authentication, role-based authorization, and RESTful API endpoints.

Extracted from the Rails API backend for [MyTurnTag Creator for iOS](https://apps.apple.com/app/myturntag-creator/id1516198303) and [MyTurnTag Creator for Android](https://play.google.com/store/apps/details?id=com.myturntag.myturntagcreator).

For more information, visit [nativeapptemplate.com](https://nativeapptemplate.com).

## API Documentation

[API Documentation](https://nativeapptemplate.com/api-docs/index.html)

## Features

- **Ruby on Rails 8.1**
- **PostgreSQL**
- **Solid Queue/Cable/Cache**
- **[devise_token_auth](https://github.com/lynndylanhurley/devise_token_auth)**
- **[jsonapi-serializer](https://github.com/jsonapi-serializer/jsonapi-serializer)**
- **[pundit](https://github.com/varvet/pundit)**
- **[acts_as_tenant](https://github.com/ErwinM/acts_as_tenant)**
- **[pagy](https://github.com/ddnexus/pagy)**
- **[Turbo](https://turbo.hotwired.dev/)** (real-time page updates for Number Tags Webpage)
- **Test** (Minitest)

### Included Features

- Sign Up / Sign In / Sign Out
- Email Confirmation
- Forgot Password
- CRUD Operations for Shops (Create/Read/Update/Delete)
- CRUD Operations for Shops' Nested Resource, Number Tags (ItemTags) (Create/Read/Update/Delete)
- URL Path-Based Multitenancy (prepends `/:account_id/` to URLs)
- User Invitation to Organizations
- Role-Based Permissions and Access Control
- Organization Switching UI
- Admin Panel
- Force App Version Update
- Force Privacy Policy Version Update
- Force Terms of Use Version Update
- And more!

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
* [Overmind](https://github.com/DarthSim/overmind) - `brew install tmux overmind` - helps run all your processes in development

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

## Running NativeAppTemplate API on your Wi-Fi

`bin/dev` binds Rails to the current Wi-Fi IP (auto-detected via `ipconfig getifaddr en0`), so the dev server is reachable from both the host browser and from any phone on the same network at `http://<wifi-ip>:3000`. To check the IP: `ipconfig getifaddr en0` (or System Settings → Network). If `en0` isn't Wi-Fi on your machine (wired-primary, Thunderbolt networking), copy `.env.sample` to `.env` and set `HOST` to the correct interface's IP. Never use `127.0.0.1`, `localhost`, or `0.0.0.0` — Rails and the mobile apps must agree on the same Wi-Fi IP.

To run your application, you'll use the `bin/dev` command:

```bash
bin/dev
```

This starts up Overmind running the processes defined in `Procfile.dev`. We've configured this to run the Rails server out of the box.

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on reporting issues, proposing changes, and submitting pull requests.

This project adheres to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## Security

If you discover a security vulnerability, please follow the disclosure process in [SECURITY.md](SECURITY.md). Do not open public issues for security concerns.

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.
