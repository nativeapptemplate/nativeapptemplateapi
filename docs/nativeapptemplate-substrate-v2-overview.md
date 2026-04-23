# NativeAppTemplate Substrate v2 - Design Overview

**Date:** 2026-04-23
**Status:** Approved for execution
**Scope:** Transform NativeAppTemplate from a walk-in queue template into a generic single-resource CRUD substrate, driven by `nativeapptemplate-agent`

---

## 1. Motivation

### 1.1 Current state

`NativeAppTemplate` is a 3-platform SaaS boilerplate (Rails 8.1 API + SwiftUI iOS + Jetpack Compose Android) extracted from `MyTurnTag`, a production walk-in queue management app. The template carries queue-specific features — NFC tag scanning, QR code generation, customer-facing scan flows, `queue_number` labels like "A001".

`nativeapptemplate-agent` is a Claude Code agent that takes a natural-language spec (e.g. `"a personal task tracker with due dates"`) and customizes the substrate for that domain by renaming identifiers.

### 1.2 The problem

The agent can rename identifiers (class names, file names, field names) but cannot rewrite queue-specific semantics, NFC hardware integration, or customer-scan flows. When the agent generates a "task tracker" from this substrate, users see:

- NFC tag writing screens in a task tracker
- QR code generation in a bookmark manager
- "A001" labels where "Buy groceries" should appear
- Customer-facing `/display/shops/:id/item_tags/completings` routes in a recipe collection

The substrate is not domain-agnostic enough for the agent's purpose.

### 1.3 The goal

Transform the substrate into a clean **parent-child CRUD template**:

- `Shop` (parent) `has_many` `ItemTag` (child) with a binary toggle state
- No NFC, no QR, no customer-facing flows, no queue-specific fields
- Generic role system (admin / member) instead of queue-operator hierarchy
- UI labels aligned with identifiers so the agent can rename both consistently

After this refactor, the agent can generate usable apps for domains like task trackers, shopping lists, reading lists, bookmark managers, recipe collections, habit trackers, expense trackers, and contact managers — any single-resource CRUD app with a parent-child structure.

---

## 2. Final Substrate Definition

### 2.1 Data model

```
Shopkeeper (user)
  └─ belongs_to multiple Accounts via AccountsShopkeeper
       └─ each Account has_many Shops
            └─ each Shop has_many ItemTags
```

#### Shop (parent resource, unchanged from current schema)

| Column | Type | Notes |
|---|---|---|
| id | bigint | PK |
| account_id | bigint | FK, `acts_as_tenant` scope |
| created_by_id | bigint | FK to Shopkeeper |
| name | string | NOT NULL |
| description | text | |
| time_zone | string | |
| created_at / updated_at | datetime | |

#### ItemTag (child resource, refactored)

| Column | Type | Notes | Change |
|---|---|---|---|
| id | bigint | PK | unchanged |
| account_id | bigint | FK | unchanged |
| shop_id | bigint | FK | unchanged |
| created_by_id | bigint | FK to Shopkeeper | unchanged |
| completed_by_id | bigint | FK to Shopkeeper, nullable | unchanged |
| **name** | string | NOT NULL | **renamed from `queue_number`** |
| **description** | text | | **new** |
| **position** | integer | nullable, for sort order | **new** |
| state | integer | enum: idled (0) / completed (1) | unchanged |
| completed_at | datetime | | unchanged |
| created_at / updated_at | datetime | | unchanged |
| ~~queue_number~~ | | | **removed (renamed to `name`)** |
| ~~scan_state~~ | | | **removed (queue-specific)** |
| ~~customer_read_at~~ | | | **removed (queue-specific)** |
| ~~already_completed~~ | | | **removed (queue edge case)** |

#### Auth / tenancy models (preserved)

- `Shopkeeper` — user, Devise-authenticated
- `Account` — tenant container
- `AccountsShopkeeper` — join table, many-to-many
- `AccountsInvitation` — pending invitations (preserved for multi-tenant future, not exposed in Free client UI)

#### Role / Permission (redesigned)

| Before | After |
|---|---|
| 7 roles: admin, senior_manager, junior_manager, senior_member, junior_member, guest, (owner implicit) | 2 roles: **admin**, **member** |
| 9 permissions mixing queue-specific and generic | Generic CRUD primitives only |

**New permission set** (tentative, finalized in Phase 1):
- `create_shops`
- `update_shops`
- `delete_shops`
- `update_organizations`
- `invitation`
- `read_data`

**Role → Permission mapping (collaborative SaaS model, Notion-style)**:

| Permission | admin | member |
|---|---|---|
| create_shops | ✓ | ✓ |
| update_shops | ✓ | ✓ |
| delete_shops | ✓ | ✓ |
| update_organizations | ✓ | |
| invitation | ✓ | |
| read_data | ✓ | ✓ |

**ItemTag access** (no separate permissions — uses Shop permissions):
- `read_data` → index, show item_tags
- `update_shops` → create, update, destroy, state toggle item_tags

See section 6.10 for rationale on the unified permission approach.

#### Version enforcement (preserved)

- `AppVersion`, `PrivacyVersion`, `TermsVersion` — unchanged

### 2.2 API contract changes

**Endpoints removed**:
- `POST /scan`, `GET /scan_customer` (static controller NFC handoff)
- `GET /display/shops/:id` and all nested display routes (customer-facing)
- `GET /display/shops/:shop_id/item_tags/completings`

**Endpoints kept / renamed**:
- `api/v1/shopkeeper/shops` CRUD — unchanged
- `api/v1/shopkeeper/shops/:shop_id/item_tags` CRUD — unchanged (same route, new schema)
- `api/v1/shopkeeper/permissions` — unchanged (returns smaller permission set now)
- Authentication (devise_token_auth) — unchanged
- Invitations — unchanged

**Endpoints unchanged but with behavior change**:
- `POST /api/v1/shopkeeper/shops/:shop_id/item_tags` — no longer auto-generates A001-A010; creates a single item with user-supplied `name`
- `POST /api/v1/shopkeeper/shops` — creating a Shop now auto-generates exactly 1 "Sample" ItemTag (instead of 10 queue-number items), so new users see a reference item on the Shop detail screen instead of an empty state

### 2.3 UI contract

**Free client (single-tenant personal UI)**:
- Tabs: Shops, Settings (no Scan, no Organizations)
- Shop list → Shop detail (shows ItemTag list) → ItemTag detail/edit
- No role UI, no invitation UI, no organization switcher
- Internally uses 1 default Account created automatically on signup

**Paid client (multi-tenant UI)**:
- Tabs: Shops, Organizations, Settings
- Same Shop → ItemTag flow as Free
- Organization switcher, member list, invitation flow
- 2-tier role UI (admin / member) for member management
- Role-gated actions (admin-only: invite, organization settings)

### 2.4 UI label alignment

To enable the agent to rename both identifiers AND UI strings consistently, all domain-specific UI strings in the substrate must align with their identifiers:

| Identifier | UI label (current) | UI label (new) |
|---|---|---|
| `ItemTag` | "Number Tag", "Number Tags" | **"Item Tag", "Item Tags"** |
| `Shop` | "Shop", "Shops" | unchanged (already aligned) |
| `Shopkeeper` | "Shopkeeper" | unchanged (already aligned) |
| `.idled` | "Idling" | **"Idled"** (align with enum value) |
| `.completed` | "Completed" | unchanged |

This lets the agent apply humanize + pluralize rules to rename `"Item Tag"` → `"Todo"`, `"Item Tags"` → `"Todos"` automatically when renaming `ItemTag` → `Todo`.

---

## 3. What Gets Removed

### 3.1 Rails API (`nativeapptemplateapi`)

**Code**:
- `ItemTag` queue-specific fields: `queue_number` (renamed), `scan_state`, `customer_read_at`, `already_completed`
- `Shop#create_default_item_tags!` (auto-generates A001-A010) — **replaced** with `Shop#create_sample_item_tag` (generates single generic "Sample" item for first-run UX)
- `Shop#reset!` (queue-specific bulk reset)
- `Shop#latest_completed_item_tag` (queue-specific helper; verify no other use)
- `Shop#full_reload_entire_page` (turbo_stream broadcast for queue display)
- `static_controller#scan` and `scan_customer` actions
- `static_controller#index` action if view is empty
- Entire `display/` namespace (controllers, views, routes, tests)
- `NumberTag` UI terminology everywhere

**Permissions removed from fixtures**:
- `manage_tags`
- `write_info_to_tags`
- `reset_all_tags`
- `complete_or_reset_tags`
- `show_tag_info`

**Roles removed from fixtures**:
- `senior_manager`
- `junior_manager`
- `senior_member`
- `junior_member`
- `guest`
- The existing `admin` role is preserved conceptually but its permission set is rewritten

**Routes removed**:
- `get "scan"`, `get "scan_customer"`
- `namespace :display do ... end` (entire block)
- Role/permission-specific routes remain (e.g. `api/v1/shopkeeper/permissions`)

**Sales-site-specific**: see section 3.4.

### 3.2 iOS Paid (`NativeAppTemplate`)

- All ItemTag screens showing queue semantics (queue_number display, scan tab, customer-scanned badges)
- CoreNFC framework integration and all NFC-related code
- QR code generation views and utilities
- `Scan` tab in the tab bar
- `Info.plist` entries: `NFCReaderUsageDescription`, entitlements for NFC
- Role management UI: downsize from 7-role selector to 2-role toggle (admin/member)
- UI label: "Number Tag" → "Item Tag" throughout

### 3.3 iOS Free (`NativeAppTemplate-Free-iOS`)

- All ItemTag queue UI (same as Paid)
- CoreNFC, QR code (same as Paid)
- Scan tab (same as Paid)
- Any residual role/invitation/organization UI (Free should have none by design, but verify)
- UI label: "Number Tag" → "Item Tag"

### 3.4 Android Paid (`NativeAppTemplate`, Kotlin/Compose)

Mirror of iOS Paid, with Android-specific considerations:
- `android.nfc.*` imports and `NfcAdapter` usage
- `<uses-permission android:name="android.permission.NFC" />` in `AndroidManifest.xml`
- `<uses-feature android:name="android.hardware.nfc" />`
- NFC intent filters
- QR code generation (probably ZXing or similar)
- Scan tab/navigation destination
- Role UI downsized to 2-tier
- `strings.xml` updates: "Number Tag" → "Item Tag"

### 3.5 Android Free (`NativeAppTemplate-Free-Android`)

Mirror of iOS Free, with Android-specific considerations.

### 3.6 Sales site (`nativeapptemplate`)

- `/roles` page: rewrite from 7-row × 11-column table to 2-row × 6-column
- Product descriptions: remove NFC / QR / Number Tag references, describe the substrate as a generic CRUD template
- Footer / nav: remove `/roles` link if rewriting is deferred; otherwise update link text
- Screenshots showing queue UI: flag for replacement (not required in this refactor)

---

## 4. What Gets Added

### 4.1 Rails API

- `ItemTag.description` (text, nullable)
- `ItemTag.position` (integer, nullable)
- `ItemTag.name` (renamed from `queue_number`, NOT NULL)
- Composite index on `item_tags (shop_id, position)` for sort performance
- `validates :name, presence: true` in `ItemTag` model
- `Shop#create_sample_item_tag` — new after_create callback that generates a single "Sample" ItemTag (replacing the old queue-number auto-generation). This gives new Shops a non-empty detail screen without domain-specific queue terminology.

### 4.2 Clients

No new features. All changes are simplifications of existing UI.

### 4.3 Agent (`nativeapptemplate-agent`)

New rename logic (Phase 6):
- **String literal rename**: for each identifier rename pair `[From, To]`, also rename `"From humanized"` → `"To humanized"` in string literals, with pluralization (e.g. `"Item Tag"` → `"Todo"`, `"Item Tags"` → `"Todos"`)
- **State vocabulary translation**: planner proposes domain-appropriate rename for `idled` / `completed` states (e.g. `"pending" / "done"` for task trackers, `"unchecked" / "checked"` for shopping lists)

---

## 5. Execution Plan

Total estimate: **8-11 days** (solo developer with Claude Code assistance).

### Phase 0: Reset and prepare (already complete)

- Day 1 work was never committed to `main`, so no rollback needed.
- `v1.0.0-with-nfc` tags and `v1-with-nfc` branches exist on all 3 substrate repos (Rails API, iOS Free, Android Free) as safety net.
- Current `main` branches are clean on all repos.

### Phase 1: Rails API refactor (1-1.5 days)

**Scope**: transform the API to match the new substrate definition.

**Approach**: work directly on `main` (no existing customers, breaking changes safe).

**Deliverables**:
1. ItemTag schema refactored (columns removed, renamed, added)
2. ItemTag controllers / serializers / policies / tests updated
3. NFC-related routes and static scan actions removed
4. Display namespace fully removed
5. Role/Permission redesigned: 2 roles × ~6 permissions
6. Shop model simplified (no default item tag generation, no reset)
7. All tests green, DB rebuilds from clean state, Shop CRUD works end-to-end

**Detailed checklist**: see `phase1-rails-api.md`.

### Phase 2: iOS Paid refactor (1.5-2 days)

**Scope**: update the paid iOS client to match the new API contract.

**Deliverables**:
1. Remove NFC / QR / scan UI and code
2. Replace queue UI with generic ItemTag list (name, description, state badge, completed timestamp)
3. Rewrite role management UI to 2-tier (admin/member)
4. Update UI strings ("Number Tag" → "Item Tag")
5. Remove NFC capability from `Info.plist` and entitlements
6. `xcodebuild SUCCEEDED` and manual simulator test passes

**Paid-primary rule**: PRs merged here are the reference for Phase 3 (iOS Free).

### Phase 3: iOS Free refactor (1 day)

**Scope**: mirror the iOS Paid changes into the iOS Free client, removing anything that's multi-tenant-only.

**Deliverables**:
1. Apply same refactors as Phase 2 (ItemTag UI, NFC removal, etc.)
2. Verify no role / invitation / organization UI is present (Free is single-tenant)
3. `xcodebuild SUCCEEDED` and simulator test passes

**Per-platform completion rule**: iOS (Paid + Free) must both build green before moving to Android.

### Phase 4: Android Paid refactor (1.5-2 days)

**Scope**: Android equivalent of Phase 2.

**Deliverables**:
1. Remove NFC / QR / scan UI and code
2. Update `AndroidManifest.xml` (remove NFC permissions and features)
3. Update `strings.xml` ("Number Tag" → "Item Tag")
4. Rewrite role UI to 2-tier
5. `./gradlew assembleDebug` BUILD SUCCESSFUL, emulator test passes

### Phase 5: Android Free refactor (1 day)

**Scope**: Android equivalent of Phase 3.

**Deliverables**: same pattern as iOS Free.

### Phase 6: Agent rename logic enhancement (1-2 days)

**Scope**: extend `nativeapptemplate-agent` to rename UI strings and state vocabulary.

**Deliverables**:
1. **String literal rename**: when renaming identifier `ItemTag` → `Todo`, also rewrite `"Item Tag"` / `"Item Tags"` string literals to `"Todo"` / `"Todos"` across all 3 platforms
2. **Humanize/pluralize helpers**: `ItemTag` → `"Item Tag"`, `Todo` → `"Todos"` (plural)
3. **State vocabulary translation**: planner proposes domain-appropriate names for `idled` / `completed` enums; workers apply the rename
4. Test with 3+ diverse specs (task tracker, recipe collection, bookmark manager)

### Phase 7: Agent test spec update + regression testing (1 day)

**Scope**: validate the full agent pipeline against the new substrate.

**Deliverables**:
1. Update or replace existing test specs (e.g. `clinic-queue` no longer applicable — rewrite as a single-resource version or drop)
2. Add new canonical test specs for various domains
3. Run agent end-to-end: spec → planner → 3 workers → judge → build green
4. Manual UI verification on simulator/emulator for each test spec

### Phase 8: Sales site update (0.5-1 day)

**Scope**: align `nativeapptemplate.com` with the new substrate capabilities.

**Deliverables**:
1. Rewrite `/roles` page to reflect admin/member 2-tier
2. Update product pages (remove NFC/QR/queue language)
3. Update hero / features sections to describe the agent-driven workflow

---

## 6. Key Design Decisions (for context)

### 6.1 Why keep `ItemTag` as the child model name

The agent's planner prompt (see `nativeapptemplate-agent` SYSTEM_PROMPT) already treats `ItemTag` as a rename target with reserved vocabulary exclusions. Renaming the substrate's `ItemTag` to something else would require updating the planner prompt too, and there's no practical benefit. The identifier `ItemTag` only appears in code, which the agent rewrites anyway.

### 6.2 Why keep `idled` / `completed` state names

Same reason: the planner prompt names these explicitly, and the agent's state vocabulary translation (Phase 6) handles domain-appropriate renames downstream.

### 6.3 Why rename UI label from "Number Tag" to "Item Tag"

The agent can rename identifiers but cannot rewrite arbitrary string literals without guidance. By aligning the UI label with the identifier (`ItemTag` identifier ↔ `"Item Tag"` label), the agent can apply a humanize rule: `humanize(identifier) == literal`, so both get renamed together. "Number Tag" is a queue-specific label that breaks this alignment.

### 6.4 Why remove NFC and QR code entirely rather than feature-flag them

- NFC and QR are hardware-integrated, deeply embedded features — not cleanly switchable
- The substrate is meant to be a clean baseline; dead code in feature-flagged-off state clutters the agent's rename scope
- Any domain that actually needs NFC or QR can add it as a custom feature post-generation

### 6.5 Why 2-tier role (admin/member) instead of removing roles entirely

- Roles are a generic SaaS feature that agents will need for team-capable apps
- The queue-specific 7-tier hierarchy collapses into 2 meaningful tiers once queue operations are removed
- Invitation + role UI is a common team-app expectation; keeping it cheap (2 tiers) preserves optionality
- Free client hides the role UI entirely; Paid client shows the 2-tier

### 6.6 Why keep `AccountsInvitation` and multi-account structure in the API

- One API serves both Free and Paid clients; keeping the multi-tenant plumbing in the API costs little
- Easier for a Free client to upgrade to Paid (no DB migration needed if the API already supports multi-tenancy)
- The Free client simply doesn't expose the invitation UI; the API endpoints are never called

### 6.7 Why work on `main` branch directly

- Zero existing customers — breaking changes carry no external cost
- Simpler git history than feature branches
- Safety net tags (`v1.0.0-with-nfc`) allow full rollback at any point

### 6.8 Why Paid-first, then Free

- Paid is the superset (more screens, more features)
- Easier to subtract UI than to retrofit features
- Paid PRs serve as reference for Free implementation (same changes, different scope)

### 6.9 Why per-platform completion (iOS Paid + iOS Free → Android Paid + Android Free)

- Keeps related code fresh in memory
- Reduces context-switching cost
- Allows iOS validation to inform Android design decisions

### 6.10 Why no separate ItemTag permissions

ItemTag is a child of Shop. Modern collaborative SaaS (Notion, Linear, Trello) treat parent-level permissions as implicitly applying to children. Adding separate ItemTag permissions would:

- Double the permission count (shop-level + item-tag-level)
- Complicate the role-permission matrix for a 2-tier role system
- Be overkill given that admin and member have nearly identical capabilities in this design

The policy file resolves ItemTag operations to Shop permissions:
- `read_data` → index, show
- `update_shops` → create, update, destroy, state toggle

This matches "collaborative SaaS" model (Notion/Linear/Trello-style): both admin and member can freely CRUD resources; admin's only extra capability is team management (invitation, organization settings).

If a future agent-generated domain requires operational separation (e.g., clinic staff can toggle item state but only admin can create items), a new `toggle_item_tags` permission can be introduced alongside a third role tier at that time. For now, keeping permissions minimal is aligned with YAGNI.

### 6.11 Why admin and member can both create and modify resources

An alternative design (operational SaaS model) would restrict resource creation or state changes to admin only. We chose the collaborative model because:

- ~90% of agent-generatable domains (task trackers, shopping lists, reading lists, bookmark managers, recipe collections, habit trackers) are collaborative by nature
- The operational model (clinic waitlist, factory inventory, restaurant service) is a specialized case
- In collaborative apps, "member" implies peer collaborator, not restricted user
- If a domain needs the operational model later, a third role tier (`viewer` or `staff`) can be added

---

## 7. Rollback Strategy

If any phase reveals an architectural problem requiring full revert:

```bash
# For each substrate repo:
git checkout v1-with-nfc
```

The `v1.0.0-with-nfc` tag preserves an immutable snapshot; the `v1-with-nfc` branch allows future patches if needed.

Agent repo (`nativeapptemplate-agent`) has no tag, but is version-controlled via PR history and can be reverted commit-by-commit.

Sales site has no pre-existing safety branch; use `git reflog` if rollback is needed.

---

## 8. Context for Claude Code

### 8.1 Project ecosystem

- **Rails 8.1 API** (`nativeapptemplateapi`): PostgreSQL, devise_token_auth, Pundit, acts_as_tenant, Solid Queue/Cable/Cache, madmin admin UI
- **iOS Paid** (`NativeAppTemplate`): Swift 6, SwiftUI, iOS 26.2+, MVVM, @Observable, Swift Testing, Liquid Glass design language
- **iOS Free** (`NativeAppTemplate-Free-iOS`): same stack as Paid, subset of features
- **Android Paid** (`NativeAppTemplate` Android): Kotlin, Jetpack Compose, Hilt, Retrofit2, Proto DataStore, API 26+
- **Android Free** (`NativeAppTemplate-Free-Android`): same stack, subset
- **Sales site** (`nativeapptemplate`): Rails 8 with ERB views, Tailwind CSS
- **Agent** (`nativeapptemplate-agent`): TypeScript, Claude Agent SDK, multi-agent architecture (planner + 3 workers + judge)

### 8.2 Rails fixture loading

The Rails API uses a custom fixture system in `db/fixtures/<env>/` (not standard `db/seeds.rb`). Identify the loading rake task before running fixture-related commands. Look in `lib/tasks/` or the README.

### 8.3 What to avoid

- Do NOT resurrect the Day 1 approach of fully deleting `ItemTag`. The Shop detail screen becomes empty without a child resource, and the agent's planner prompt assumes `ItemTag` exists as a rename target.
- Do NOT introduce a new child model name (e.g. `ShopItem`). Keeping `ItemTag` aligns with the agent's planner prompt.
- Do NOT add i18n / Localizable.strings indirection in Phase 2-5. UI strings should be direct literals so the agent's string-literal rename (Phase 6) can operate on them.
- Do NOT touch the `AccountsInvitation` model or multi-account join table. Those stay; Free client just hides their UI.

### 8.4 What to watch for (common pitfalls)

- Fixture files exist per-environment (`db/fixtures/{development,test,staging,production}/`). Changes must apply to all 4.
- `rolified.rb` concern may hard-code role tags — check before changing roles.
- Shop model may reference ItemTag via `has_many` and instance methods (`reset!`, `latest_completed_item_tag`, `create_default_item_tags!`). Remove cleanly.
- `full_reload_entire_page` on Shop uses `turbo_stream` — check all callers before removing.
- iOS/Android paid clients may have role-gated navigation. Simplifying to admin/member may break some flows unless the navigation logic is audited.

---

## 9. Next Step

Begin Phase 1. See `phase1-rails-api.md` for the detailed execution checklist.
