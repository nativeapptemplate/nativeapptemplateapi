# Changelog

## [Unreleased]

- Deploy with Kamal 2 to GitHub Container Registry instead of Render: add `Dockerfile`, `.dockerignore`, `config/deploy.yml` (kamal-proxy serving a Cloudflare Origin Certificate with `forward_headers: true` and `ssl_redirect: false`, Postgres 18 as the `db` accessory on the private Docker network, Solid Queue in Puma, Active Storage volume, amd64 builder), `.kamal/secrets`, `bin/kamal` and `bin/thrust`. Add the missing `GET /up` health check route and `assume_ssl = true` so kamal-proxy's health check passes. Add Cloudflare's ranges to `trusted_proxies` (`config/cloudflare_ips.yml`) so `rate_limit` keys on the caller rather than the edge. Remove `render.yaml`, `bin/render-*.sh` and the staging environment, which only served Render PR previews. New tests: `test/config/deploy_config_test.rb`, `test/integration/health_check_test.rb`, `test/integration/trusted_proxies_test.rb` (#144)
- Require `devise_token_auth ~> 1.3` in the Gemfile (the lockfile already resolved 1.3.0) so `bundle update` cannot step back to 1.2.x (#142)
- Apply Solid Queue 1.7's batch migrations (`db/queue_migrate`): adds `solid_queue_jobs.batch_id`, `solid_queue_batches` and `solid_queue_batch_executions`, which removes the boot warning about pending migrations required after Solid Queue 2.0 (#139)
- Align `bin/ci` with GitHub CI: `bin/ci` now runs `erb_lint`, GitHub CI now runs the `db:seed_fu` smoke test, and the CI Postgres service is pinned to `postgres:18` (#137)
- Fix `/madmin/jobs` answering 401 to signed-in admins: Mission Control's HTTP Basic auth was disabled in `config/initializers`, which runs after the engine copies its config, so it never took effect. The setting now lives in `config/application.rb`. Add tests for `AccountMiddleware` (account prefix, unknown ids, non-members get 401) and `AdminConstraint` (#136)
- Fix `POST /devices` returning 500 when two first-time registrations of the same token race: retry once and update the row the other request created (#135)
- API change: replace Rack::Attack with Rails `rate_limit`. The per-IP limit (300 requests / 5 minutes) is shared across API, auth and HTML pages via `scope: :requests_per_ip`, and API clients now get a JSON 429 `{code, error_message}` instead of plain text. Drops the `rack-attack` gem (#134)
- Document in AGENTS.md that this repo is a template and is never deployed; the Render config is for generated apps (#133)
- Destroy actions use `destroy!` and answer 422 if a `before_destroy` callback halts the destroy, instead of reporting success (#131)
- Remove dead code: a no-op `Current` reset, a test helper for a nonexistent route, and duplicate shop params; pin the shop permit list with tests (#130)
- Use `travel` instead of `sleep` in the account touch test (#129)
- Remove the unused `whenever`, `capybara` and `selenium-webdriver` gems, `config/schedule.rb`, and the CI screenshot step (#128)
- Stop caching `ItemTagSerializer`: `shop_name` came from the shop, so a renamed shop kept its old name in item tag responses for up to an hour (#126)
- Allow deleting a shopkeeper who created a shop in a team someone else owns (was a 500 from a foreign key). `shops.created_by_id` is now nullable with `ON DELETE SET NULL`; a creator is still required to create a shop (#125)
- Fix a double tap on "complete" sending the item tag notification twice: completion runs under a row lock (`ItemTag#complete_by!`) (#124)
- Remove per-row queries from the accounts and shops indexes (accounts 20 → 11 and shops 13 → 8 queries on dev data); responses are unchanged (#123)
- Link confirmation and password reset emails sent from a PR preview (staging) back to the preview instead of production (#122)
- API change: members and invitations must have at least one role (422 "Roles can't be blank"). A role-less member made `GET /permissions` raise (#121)
- API change: password reset and confirmation `redirect_url` must be on the API's own host. Other hosts get 422 for resets and fall back to the default page for confirmations (#120)
- Harden admin sign-in: rate limit by IP and email, `reset_session` on sign-in and sign-out, and Madmin now rejects a deleted admin's session (#119)
- AGENTS.md: correct the CORS and test-worker notes, and keep the test count current (#118, #127, #132)
- Clear finished Solid Queue jobs every hour via `config/recurring.yml` (#117)
- API change: `item_tags#update` no longer accepts `state`. Completion goes through the `complete`/`idle` events, and an unknown state no longer returns 500 (#116)
- API change: API errors are always JSON `{code, error_message}`, including missing records (404), missing parameters (400), unknown API routes and 500s; before, they were HTML unless the request sent a JSON Content-Type (#115)
- API change: an invitation code can only be viewed, accepted or rejected by the shopkeeper whose email it was sent to; anyone else gets 404. Lookups are rate limited (10/minute per shopkeeper) and codes come from `SecureRandom`. The 6-digit format is unchanged (#114)
- Upgrade Madmin 2.6 → 3.2 (drops Pagy), and make Active Storage blobs and variant records read-only in Madmin (#113)
- AGENTS.md: expand the testing policy (test-first bug fixes, sourced expected values, see each test fail, run the app) (#112)
- Replace Pagy with a small `Pagination` module. Page params are parsed strictly (`2abc` is now page 1); the `meta` shape is unchanged (#111)
- Remove the explicit `nokogiri` dependency (Rails already requires it) (#110)
- Speed up CI: ignore `vendor/bundle`, cancel superseded PR runs, 15-minute job timeouts (#109)
- Add unique indexes on `accounts_shopkeepers (account_id, shopkeeper_id)` and `accounts_invitations (account_id, email)` to back the uniqueness validations (#108)
- Move agent instructions from `CLAUDE.md` to `AGENTS.md` so Claude Code, Codex, and other agents share one file. `CLAUDE.md` now only imports it (`@AGENTS.md`) (#107)
- Update Ruby from 4.0.6 to 4.0.7 (#105)
- Update gems: Rails 8.1.3.1 → 8.1.4, `acts_as_tenant` 1.0.1 → 2.0.2, `json` 2.21.2 → 3.0.2, plus `noticed`, `solid_cable`, `brakeman`, `rubocop`, `rubocop-rails`, `resend`, `mission_control-jobs`, `pg`, and others. `acts_as_tenant` 2.0 tightens tenant validation: a `belongs_to` pointing at another tenant's record now fails validation even inside `without_tenant`, and ActiveJob resolves the tenant at perform time (#105)
- Update gems (mission_control-jobs, resend, rubocop, image_processing, valid_email2, bootsnap, httpx, and others). Rename `MaximumRangeSize` to `MaxRangeSize` for `Lint/MissingCopEnableDirective` in `.rubocop.yml` (RuboCop 1.90) (#100)
- Update gems (resend, solid_queue 1.7.0, webmock). Solid Queue 1.7's batch tables are not migrated yet (optional until Solid Queue 2.0) (#97)
- Update gems: `devise` 4.9.4 → 5.0.4, `devise_token_auth` 1.2.6 → 1.3.0, `madmin` 2.3.3 → 2.6.0, `solid_queue` 1.6.0, `brakeman` 8.0.6, and others. Fixes the `scan_ruby` check failing because `bin/brakeman --ensure-latest` exits non-zero when brakeman isn't the latest version (#96)
- Update Rails to 8.1.3.1 (CVE-2026-66066, Active Storage variant processing) and land the Dependabot `minor-and-patch` group (#93)
- Bump GitHub Actions `actions/checkout` 6 → 7 (#86) and `actions/cache` 5 → 6 (#88)
- Update Ruby from 4.0.3 to 4.0.6 and update gems; `faraday` 2.14.3 (CVE-2026-54297), `aasm` 5.5.2 → 6.0.0 (#90)
- Document push notification setup in CLAUDE.md (detailed) and README (feature lists, marked paid-clients only) (#76)
- Add test coverage for `google`/FCM device registration and rejection of unsupported `platform` values (#75)
- Connect to the APNs **sandbox** server in development (`connect_to_development_server: Rails.env.development?`). A Xcode debug build registers a sandbox token; pushing it to the production APNs host returned `400 BadDeviceToken`, which the gem treats as `TokenError` and destroys the device row. Development now matches the sandbox; staging/production keep production (#74)
- Add `Noticed::Event` and `Noticed::Notification` to the madmin dashboard, with cross-linkable associations (#73)
- Add `ApplicationPushDevice` to the madmin dashboard (#72)
- Fix push delivery crashing with `TypeError (no implicit conversion of nil into Hash)`: `ItemTagNotifier` now sets the `with_apple`/`with_google`/`with_data` options (Action Push Native does `{}.merge(option)` and rejects `nil`). Also fix the notification `url` to the shallow `api_v1_shopkeeper_item_tag_path` route (`item_tags` is declared `shallow: true`) (#71)
- Fix `is_admin` serializing as `null` for non-admin members: `Rolified` role predicates now coerce to a real boolean instead of returning `nil` when the role key is absent from the `roles` JSON (#70)
- Upgrade `noticed` from 2.9.3 to 3.0.0 (#69)
- Bump gems within Gemfile constraints (bootsnap, faraday, httpx, jwt, marcel, pagy, rubocop, rubocop-rails, selenium-webdriver, tailwindcss-ruby, zeitwerk) (#68)
- Ignore `CVE-2026-40295` (devise Timeoutable open redirect) in bundler-audit — `:timeoutable` isn't enabled and `devise_token_auth ~> 1.2` pins `devise < 5` (#67)
- Populate APNs/FCM credentials for development, staging, and production so `config/push.yml` resolves Action Push Native config at runtime (#66)
- Update Ruby from 4.0.2 to 4.0.3
- Update gems within Gemfile constraints (action_text-trix, bootsnap, json, mailbin, multi_xml, rubocop-rails, rubyzip)
- Wire `ItemTagNotifier` to the `ItemTag` AASM `complete` event via `after_commit`. On state transition `idled → completed`, the notifier fires to all shopkeepers in the shop's account except the completer (`completed_by`). Only the AASM trigger — APNs/FCM provider credentials still pending (`bin/rails credentials:edit` once the keys are provisioned).
- Drop the standalone `Device` model and consolidate push-token registration onto `ApplicationPushDevice` (subclass of `ActionPushNative::Device`) so `deliver_by :action_push_native` actually fires for tokens registered via `POST /api/v1/shopkeeper/devices`. The custom `devices` table is dropped; `action_push_native_devices` is rebuilt with UUID primary key + UUID polymorphic owner + `bundle_id` / `last_active_at` columns + unique `(platform, token)` index.
- API contract change (still pre-mobile-client): `device.platform` enum is now `[apple, google]` (matches Action Push Native's APNs/FCM service convention) instead of `[ios, android]`. Mobile substrate clients (PRs #3-5) will register with `apple` or `google`.
- Renames: `Device` → `ApplicationPushDevice`, `Api::Shopkeeper::DevicePolicy` → `Api::Shopkeeper::ApplicationPushDevicePolicy`, `DeviceSerializer` → `ApplicationPushDeviceSerializer` (JSONAPI `type` stays `device`); `Shopkeeper has_many :devices` → `has_many :application_push_devices, as: :owner`.

## 2026-05-10

- Add push notifications scaffolding via `noticed` v2 (#58)
- New `Device` model + migration (UUID primary key, unique on `[platform, token]`, `last_active_at` for staleness scope)
- New `Api::V1::Shopkeeper::DevicesController` — POST `/devices` is idempotent upsert (rebinds token to current shopkeeper); DELETE `/devices/:id` unregisters
- Add `ApplicationNotifier` base class + example `ItemTagNotifier` with `deliver_by :action_push_native` wiring (Apple + Google push via Rails-native `action_push_native` 0.3.x)
- Generate `ApplicationPushNotification` / `ApplicationPushDevice` / `ApplicationPushNotificationJob` and `config/push.yml` (APNs/FCM credentials still placeholders — provision via `bin/rails credentials:edit` before enabling delivery; ItemTag AASM trigger lands in a follow-up)
- Note: the existing `Device` registration API (`POST /api/v1/shopkeeper/devices`) writes to the custom `Device` model, not `ApplicationPushDevice` — bridging the two (so registered tokens flow into Action Push Native delivery) is a follow-up
- `Shopkeeper has_many :devices, :notifications`; new locale entries under `notifiers.item_tag` — title/body deliberately kept generic (`%{name}` / `%{shop}` only, no state-verbs like "completed" or "ready") so the agent's domain-adapt step can rewrite richer per-domain copy without fighting baked-in queue semantics
- 21 new test runs (Device model + DevicesController + notifier); full suite still 0 failures

## 2026-05-02

- Phase 1: Rails API substrate v2 refactor (#45) — turn queue-specific template into generic single-resource CRUD substrate (Shop → ItemTag)
- Rename `ItemTag.queue_number` → `name`; add `description`, `position`, composite `(shop_id, position)` index; drop `scan_state`, `customer_read_at`, `already_completed` and the `(shop_id, queue_number)` unique index
- Drop NFC/QR scan flows: remove `POST /scan`, `GET /scan_customer`, the entire `display/` namespace, `DELETE /shops/:id/reset`, app root + static controller
- Rename `PATCH /item_tags/:id/reset` → `/idle` (matches AASM event name)
- Auto-create one "Sample" ItemTag on Shop creation (was 10 A001–A010 queue numbers); drop `lib/tasks/shop.rake`
- Collapse `AccountsShopkeeper::ROLES` from 7 tiers (admin/senior_manager/junior_manager/senior_member/junior_member/guest) to 2 (admin/member); `ItemTagPolicy` resolves to Shop permissions
- Inline state transitions and `completed_by`/`completed_at` writes in controller actions; drop `scan_tag!`/`complete_tag!`/`reset!` model methods
- Regenerate `docs/openapi.yaml`; refresh brakeman.ignore fingerprint; update locales and Madmin resources
- Update gems within Gemfile constraints (bigdecimal, bootsnap, erb, ffi, irb, json, minitest, net-imap, nokogiri, pagy, parallel, parser, propshaft, puma, regexp_parser, rubocop, rubocop-ast, tailwindcss-ruby)

## 2026-03-10

- Update Rails from 7.1.5.1 to 8.1
- Update Brakeman from 7.0.2 to 7.1.2
- Add brakeman.ignore for mass assignment false positive
- Add comprehensive test coverage for models, policies, serializers, and controllers (205 tests)
- Update app icons with transparent backgrounds
- Add Active Storage migrations and Rails 7.2 framework defaults
- Add static error pages (404, 406, 500)
- Fix RuboCop offenses in Active Storage migrations
- Add CLAUDE.md for Claude Code guidance

## 2025-06-21

- Update Brakeman gem

## 2025-03-06

- Fix item_tag uniqueness error

## 2025-03-01

- Add item_tags table
- Remove BundleAssets

## 2025-02-08

- Migrate from Sprockets to Propshaft
- Update Madmin

## 2025-02-07

- Update Ruby and gems
- Update Brakeman gem
- Fix fail updating shopkeeper

## 2024-10-30

- First commit
