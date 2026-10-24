# NativeAppTemplate API

[![Mentioned in Awesome Rails](https://awesome.re/mentioned-badge.svg)](https://github.com/gramantin/awesome-rails#startersboilerplates)

A [Rails 8.1](https://rubyonrails.org/) API backend for NativeAppTemplate iOS/Android mobile applications. It's a multi-tenant SaaS application with token-based authentication, role-based authorization, and RESTful API endpoints.

Extracted from the Rails API backend for [MyTurnTag Creator for iOS](https://apps.apple.com/app/myturntag-creator/id1516198303) and [MyTurnTag Creator for Android](https://play.google.com/store/apps/details?id=com.myturntag.myturntagcreator).

For more information, visit [nativeapptemplate.com](https://nativeapptemplate.com).

Want a customized backend generated for you? [nativeapptemplate-agent](https://github.com/nativeapptemplate/nativeapptemplate-agent) is a Claude Code agent that turns a one-sentence spec (e.g. *"a walk-in queue for a barbershop"*) into a coherent three-platform implementation — this Rails 8.1 API plus matching [SwiftUI iOS](https://github.com/nativeapptemplate/NativeAppTemplate-Free-iOS) and [Jetpack Compose Android](https://github.com/nativeapptemplate/NativeAppTemplate-Free-Android) apps — renamed and adapted to your domain, with validation built in.

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
- **[noticed](https://github.com/excid3/noticed)** + **[action_push_native](https://github.com/basecamp/action_push_native)** (push notifications)
- **[sentry-ruby](https://github.com/getsentry/sentry-ruby)** (optional error monitoring, off unless `SENTRY_DSN` is set)
- **Test** (Minitest)

### Included Features

- Sign Up / Sign In / Sign Out
- Email Confirmation
- Forgot Password
- CRUD Operations for Shops (Create/Read/Update/Delete)
- CRUD Operations for Shops' Nested Resource, Item Tags (Create/Read/Update/Delete)
- URL Path-Based Multitenancy (prepends `/:account_id/` to URLs)
- User Invitation to Organizations
- Role-Based Permissions and Access Control
- Organization Switching UI
- Admin Panel
- Force App Version Update
- Force Privacy Policy Version Update
- Force Terms of Use Version Update
- Push Notifications (APNs for iOS, FCM for Android) — paid clients only
- Admin-Set Full Feature Access Override for subscriptions — paid clients only
- Optional Error Monitoring with Sentry (no personal data sent)
- And more!

## Deleting a shopkeeper

A shopkeeper who deletes their account (`DELETE /shopkeeper_auth`) also deletes every organization they own, with all its shops, item tags and invitations. The organization's other members stay signed up but lose that organization. Say so in the apps' delete confirmation.

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

Push notifications (used by the paid iOS/Android clients) need APNs and FCM credentials. Add them per environment with `bin/rails credentials:edit --environment <env>` under `action_push_native:apns` and `action_push_native:fcm`; see `config/push.yml` for the expected keys.

## App name and store links

`config/settings.yml` has two kinds of app name. `display_name` (`Native App Template`) is the name people read: mails (sender name, invitation text, footer) and the HTML pages use it. `site.name` and `business.name` (`NativeAppTemplate`) are the one-word identifier-like names; keep them for code that needs one.

The invitation mail links the App Store and Google Play only when `mobile_app.app_store_url` / `mobile_app.play_store_url` are set. Both are blank by default, so no placeholder link is sent; fill them in once the apps are published.

The icons in `public/` (`favicon.ico`, `icon.svg`, `icon.png`, `icon-192.png`, `icon-512.png`, `apple-touch-icon.png`) are the template's and only appear as browser favicons; replace them with your app's icons. The HTML pages (password reset, email confirmation, error pages) name the app in text with `display_name` instead of showing a logo.

## Running NativeAppTemplate API on your Wi-Fi

Copy `.env.sample` to `.env` and set `HOST` to your current Wi-Fi IP. On macOS: `ipconfig getifaddr en0`. `bin/dev` binds Rails to that address so the dev server is reachable from both the host browser and from any phone on the same network at `http://<wifi-ip>:3000`. When your Wi-Fi IP changes, update `HOST` here and the matching `NATIVEAPPTEMPLATE_API_DOMAIN` in the mobile apps (Xcode scheme for iOS, `~/.gradle/gradle.properties` for Android) — Rails fails loudly if `HOST` is unset, which keeps the three sides honest. Never use `127.0.0.1`, `localhost`, or `0.0.0.0`.

To run your application, you'll use the `bin/dev` command:

```bash
bin/dev
```

This starts up Overmind running the processes defined in `Procfile.dev`. We've configured this to run the Rails server out of the box.

## Deployment

The API deploys with [Kamal 2](https://kamal-deploy.org) to any Linux server with SSH access: `Dockerfile` builds the image, `config/deploy.yml` describes the server, and images are pushed to GitHub Container Registry (ghcr.io). PostgreSQL runs on the same server as a Kamal accessory, and Solid Queue runs inside Puma, so one small VPS is enough. The server sits behind Cloudflare: the zone's SSL/TLS mode is "Full (strict)", kamal-proxy serves a Cloudflare Origin Certificate, and the server firewall admits port 443 from [Cloudflare's ranges](https://www.cloudflare.com/ips/) only. (Without Cloudflare, switch `proxy` in `config/deploy.yml` to the Let's Encrypt variant shown in its comment.)

1. Edit `config/deploy.yml`: the server IP (`servers` and `accessories.db.host`), `image` and `registry.username` (your GitHub user or org), and `proxy.host` (also `app.domain` in `config/settings.yml`).
2. Export the secrets `.kamal/secrets` reads: `KAMAL_REGISTRY_PASSWORD` (a GitHub token with `write:packages`) and `NATIVEAPPTEMPLATEAPI_POSTGRES_PASSWORD`. `RAILS_MASTER_KEY` comes from `config/credentials/production.key`. Optionally `NATIVEAPPTEMPLATEAPI_SENTRY_DSN` (see [Error monitoring (Sentry)](#error-monitoring-sentry)).
3. Create an Origin Certificate in the Cloudflare dashboard (SSL/TLS → Origin Server) and save both halves outside the repo. Copying from the dashboard can lose the line breaks, so rewrap while saving:

```bash
pem() { ruby -e '
  s = STDIN.read
  m = s.match(/-----BEGIN ([A-Z ]+)-----(.*?)-----END \1-----/m) or abort "not a PEM"
  puts "-----BEGIN #{m[1]}-----", m[2].gsub(/\s+/, "").scan(/.{1,64}/), "-----END #{m[1]}-----"
' ; }
mkdir -p ~/.config/nativeapptemplateapi && chmod 700 ~/.config/nativeapptemplateapi
pbpaste | pem > ~/.config/nativeapptemplateapi/origin-cert.pem   # "Origin Certificate" copied
pbpaste | pem > ~/.config/nativeapptemplateapi/origin-key.pem    # "Private Key" copied
chmod 600 ~/.config/nativeapptemplateapi/origin-*.pem
openssl x509 -in ~/.config/nativeapptemplateapi/origin-cert.pem -noout -subject -enddate
```

4. First deploy:

```bash
bin/kamal setup
```

Later deploys are `bin/kamal deploy`; `bin/kamal console`, `bin/kamal logs` and `bin/kamal dbc` are defined as aliases.

## Full feature access override

The paid clients sell a subscription through RevenueCat and check the entitlement in the app; this API keeps no subscription state. To unlock every paid feature for a shopkeeper without a purchase, open the shopkeeper in `/madmin` and set **Feature access state** to `all_feature_access`. Every account that shopkeeper owns is unlocked, for its members too. The apps pick it up when they next come to the foreground (they re-read the current account then), or at the next sign-in or organization switch. Use it for:

- testing paid features on production without buying,
- staff, partner and complimentary accounts,
- the demo account you give App Review.

The apps cannot set it: sign-up and `PATCH /shopkeeper_auth` ignore `feature_access_state`. The API returns it as `feature_access_state` and `account_owner_feature_access_state` on sign-in and `owner_feature_access_state` on accounts.

The no-code alternative is a promotional entitlement, granted on the customer page of the RevenueCat dashboard. It works only with billing on, and it goes on the RevenueCat customer whose app user ID is the account owner's shopkeeper ID, not the member's.

## Error monitoring (Sentry)

The API can report unexpected errors to [Sentry](https://sentry.io) through `sentry-ruby` and `sentry-rails` (`config/initializers/sentry.rb`). It is optional and off by default.

### Turning it on

Sentry is off unless `SENTRY_DSN` is set. Without it the SDK is never initialised and the app behaves exactly as if the gems were not there, which is how development and test run.

In production the DSN is a Kamal secret: `config/deploy.yml` lists `SENTRY_DSN` under `env.secret`, and `.kamal/secrets` reads it from `NATIVEAPPTEMPLATEAPI_SENTRY_DSN` on the deploying machine. To turn it on:

1. Create a Ruby on Rails project in Sentry and copy its DSN (Project Settings → Client Keys).
2. Export it where you export the other deploy secrets: `export NATIVEAPPTEMPLATEAPI_SENTRY_DSN=https://...`. Keep it out of the repo.
3. `bin/kamal deploy`.

To turn it off again, unset the variable and redeploy: the container gets an empty `SENTRY_DSN`. Without Kamal, set `SENTRY_DSN` in the app's environment however your platform does it.

Events are sent only from the `production` environment; any other environment with a DSN initialises the SDK but sends nothing. The release is the deployed git SHA (`KAMAL_VERSION`, set by Kamal in the container).

### What is sent

Sentry's free plan allows 5,000 errors a month, so only real bugs are sent: unhandled exceptions in requests (500s) and in Active Job / Solid Queue jobs (covered by sentry-rails). Not sent:

- Anything the API answers with a 4xx through `rescue_from` in `Api::V1::Shopkeeper::BaseController` (not found, Pundit denials, missing parameters, failed destroys), and the `account_not_found` / `not_account_member` organization errors.
- Exceptions Rails turns into 4xx responses: sentry-rails' defaults (`ActiveRecord::RecordNotFound`, `ActionController::RoutingError`, `ActionController::ParameterMissing`, ...) plus `ActiveRecord::RecordInvalid`, `ActiveRecord::RecordNotDestroyed` and `Pundit::NotAuthorizedError` (`NativeapptemplateSentry::EXPECTED_EXCEPTIONS`; add your own expected exceptions there).
- Errors the code rescues and logs itself, such as a failure to create a new shop's sample item tag.
- Performance traces, profiles and breadcrumbs (all disabled).

### Privacy

- The user on an event is the shopkeeper's ID only, and the event is tagged with the current account's ID (`SetCurrentRequestDetails`). No email, name or IP address.
- `send_default_pii` is off: request bodies, query strings, cookies and the client IP are not collected.
- `before_send` drops the `devise_token_auth` headers (`Authorization`, `access-token`, `client`, `uid`, `expiry`, `token-type`), replaces anything that looks like an email address in exception messages and the URL with `[FILTERED EMAIL]`, and applies `Rails.application.config.filter_parameters` to any request data and extras.
- Never pass an email or a name to `Sentry.set_user`, `Sentry.set_extras` or `Sentry.capture_message`.

`test/config/sentry_test.rb` and `test/integration/sentry_context_test.rb` cover these rules.

### Recommended Sentry settings

Sentry still derives the user's IP address and location from the connection on its side. Turn that off in **Organization Settings → Security & Privacy**:

- Enable **Prevent Storing of IP Addresses**.
- Under **Advanced Data Scrubbing**, add a rule: Method **Remove**, Data Type **Anything**, Source `$user.geo.**`. The IP setting alone does not drop the location Sentry computes from the IP, so this rule is needed as well.

If your users are in the EU, also pick the EU data region when you create the Sentry organization.

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on reporting issues, proposing changes, and submitting pull requests.

This project adheres to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## Security

If you discover a security vulnerability, please follow the disclosure process in [SECURITY.md](SECURITY.md). Do not open public issues for security concerns.

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.
