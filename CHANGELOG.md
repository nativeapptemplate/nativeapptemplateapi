# Changelog

## [Unreleased]

## 2026-05-10

- Add push notifications scaffolding via `noticed` v2 (#58)
- New `Device` model + migration (UUID primary key, unique on `[platform, token]`, `last_active_at` for staleness scope)
- New `Api::V1::Shopkeeper::DevicesController` — POST `/devices` is idempotent upsert (rebinds token to current shopkeeper); DELETE `/devices/:id` unregisters
- Add `ApplicationNotifier` base class + example `ItemTagCalledNotifier` (no provider config yet — APNs / FCM delivery + ItemTag AASM wiring land in PR #2 once credentials are provisioned)
- `Shopkeeper has_many :devices, :notifications`; new locale entries under `notifiers.item_tag_called`
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
