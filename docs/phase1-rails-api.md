# Phase 1: Rails API Refactor (Execution Checklist)

**Repo:** `~/pg/ruby/pg/nativeapptemplateapi`
**Branch:** `main`
**Prerequisites:**
- `v1.0.0-with-nfc` tag and `v1-with-nfc` branch exist (safety net)
- `bin/rails test` currently passes (405 tests, 814 assertions, 0 failures as of 2026-04-23)
- Current branch is `main` and `git status` is clean

**Goal:** Transform the Rails API from a queue-specific template into a generic single-resource CRUD substrate. See `nativeapptemplate-substrate-v2-overview.md` for context.

**Estimated time:** 1-1.5 days (6-10 hours)

---

## Overall Strategy

Work in the following order (reverse of dependency):

1. Routes (delete first to surface broken references)
2. Controllers (depend on routes)
3. Views (depend on controllers)
4. Serializers / policies / madmin resources
5. Models (Shop, ItemTag) — refactor, not delete
6. Migrations (schema changes)
7. Fixtures (permissions, roles, roles_permissions)
8. Locales, settings, docs cleanup
9. Test fixes
10. Final verification

One commit per logical step. Push to `origin/main` at end of each step. Never leave `main` in a broken state between steps.

---

## Step 1: Baseline check and pre-work

### 1.1 Confirm starting state

```bash
cd ~/pg/ruby/pg/nativeapptemplateapi

# Confirm on main and clean
git branch --show-current
git status

# Confirm baseline tests pass
bin/rails test

# Confirm DB rebuild works from clean state
bin/rails db:drop db:create db:migrate
bin/rails test
```

Expected: 405 tests, 0 failures.

### 1.2 Identify fixture loading command

The Rails API uses a custom fixture system. Find the loading mechanism:

```bash
grep -rn "fixtures" lib/tasks/ 2>/dev/null
cat Rakefile | grep -i fixture
ls lib/tasks/
```

Typical patterns found:
- Custom rake task like `bin/rails db:fixtures:load_env[development]`
- Or `FIXTURES_PATH=db/fixtures/development bin/rails db:fixtures:load`

Document the exact command for use throughout this phase.

### 1.3 Inventory of targets

```bash
# ItemTag references
git grep -l "ItemTag\|item_tag\|NumberTag\|number_tag\|Number Tag" > /tmp/p1-itemtag-files.txt

# NFC / QR / Scan (Rails side)
git grep -l "nfc\|NFC\|qr_code\|QRCode\|scan_state\|customer_read_at\|queue_number\|already_completed" \
  > /tmp/p1-queue-fields.txt

# Permission / Role references
git grep -l "manage_tags\|write_info_to_tags\|reset_all_tags\|complete_or_reset_tags\|show_tag_info" \
  > /tmp/p1-queue-permissions.txt
git grep -l "senior_manager\|junior_manager\|senior_member\|junior_member\|\"guest\"" \
  > /tmp/p1-removed-roles.txt

# Display namespace
git grep -l "display_shop\|Display::\|display/shops\|display/item_tags" > /tmp/p1-display.txt

# Static controller
cat app/controllers/static_controller.rb
```

Review each output. This becomes the deletion map.

---

## Step 2: Remove routes

### 2.1 Edit `config/routes.rb`

Remove:
- `get "scan"` (static controller NFC handoff)
- `get "scan_customer"` (static controller NFC customer flow)
- The entire `namespace :display do ... end` block

Keep:
- `root to: "static#index"` (if present — verify static#index view exists and is non-empty; if empty, also remove)
- `scope controller: :static do; get :index; end` (same verification)
- All `api/v1/shopkeeper/...` routes including `item_tags` (schema changing, endpoint stays)
- `madmin` namespace
- Authentication routes

### 2.2 Edit `config/routes/madmin.rb`

No change needed for ItemTag (the madmin resource stays, schema changes only).

### 2.3 Verify

```bash
bin/rails routes 2>/dev/null | grep -iE "scan|display"
# Expected: empty

bin/rails runner "puts 'routes loaded ok'"
```

Tests will fail at this point because controllers still reference deleted routes. That's expected.

### 2.4 Commit

```bash
git add config/routes.rb
git commit -m "Remove NFC scan routes and display namespace"
```

---

## Step 3: Remove display namespace controllers, views, tests

### 3.1 Delete files

```bash
git rm -r app/controllers/display/
git rm -r app/views/display/
git rm -r test/controllers/display/
git rm -r test/integration/display/
```

### 3.2 Commit

```bash
git commit -m "Remove display namespace"
```

---

## Step 4: Remove static controller scan actions (and controller itself if empty)

### 4.1 Inspect `app/controllers/static_controller.rb`

If the file only contains `scan`, `scan_customer`, and a trivial `index` method with an empty view:

```bash
cat app/views/static/index.html.erb
```

If empty, remove the entire static controller:

```bash
git rm app/controllers/static_controller.rb
git rm app/views/static/index.html.erb
rmdir app/views/static 2>/dev/null
[ -f test/controllers/static_controller_test.rb ] && git rm test/controllers/static_controller_test.rb
```

Also remove routes:
- `scope controller: :static do; get :index; end`
- `root to: "static#index"`

If these are removed, the app has no root route. This is acceptable for an API-only app.

Otherwise (if static#index has real content), only remove the scan actions:

```ruby
# Keep def index, remove def scan and def scan_customer
```

### 4.2 Verify

```bash
bin/rails routes 2>/dev/null | grep -iE "static|^\s*root"
bin/rails runner "puts 'loaded ok'"
```

### 4.3 Commit

```bash
git add .
git commit -m "Remove static controller scan actions"
```

---

## Step 5: Refactor ItemTag schema

### 5.1 Create migration

```bash
bin/rails generate migration RefactorItemTagToGenericCrud
```

Edit the generated file:

```ruby
class RefactorItemTagToGenericCrud < ActiveRecord::Migration[8.1]
  def change
    # Remove queue-specific columns
    remove_column :item_tags, :scan_state, :string
    remove_column :item_tags, :customer_read_at, :datetime
    remove_column :item_tags, :already_completed, :boolean

    # Rename queue_number to name
    rename_column :item_tags, :queue_number, :name

    # Apply NOT NULL constraint to name
    change_column_null :item_tags, :name, false

    # Add new generic columns
    add_column :item_tags, :description, :text
    add_column :item_tags, :position, :integer

    # Composite index for sort performance
    add_index :item_tags, [:shop_id, :position]
  end
end
```

**Before running the migration**: verify the actual column types in the current schema:

```bash
cat db/schema.rb | grep -A 20 "create_table \"item_tags\""
```

Adjust the migration if the current types differ (e.g., if `already_completed` is `:boolean`, keep it; if it's `:integer`, change).

### 5.2 Run migration

```bash
bin/rails db:drop db:create db:migrate
```

Verify schema:

```bash
cat db/schema.rb | grep -A 30 "create_table \"item_tags\""
```

Expected columns (in some order):
- id, account_id, shop_id, created_by_id, completed_by_id
- name (not null), description, position
- state, completed_at
- created_at, updated_at

### 5.3 Commit

```bash
git add db/migrate/*_refactor_item_tag_to_generic_crud.rb db/schema.rb
git commit -m "Refactor ItemTag schema: rename queue_number, add description/position, remove queue-specific fields"
```

---

## Step 6: Update ItemTag model

### 6.1 Edit `app/models/item_tag.rb`

**Remove**:
- Any references to `queue_number`, `scan_state`, `customer_read_at`, `already_completed`
- `scan_tag!` method (NFC handling)
- `sorted_recent_first_order` and other queue-specific scopes (inspect for relevance; keep if generic)
- Any methods that compose "A001" format numbers

**Add**:
- `validates :name, presence: true`

**Keep**:
- `belongs_to :shop`, `belongs_to :account`, etc.
- `belongs_to :created_by, class_name: "Shopkeeper"`
- `belongs_to :completed_by, class_name: "Shopkeeper", optional: true`
- `enum :state, { idled: 0, completed: 1 }` (or whatever the current enum definition is)
- `acts_as_tenant :account`

Expected end state (roughly):

```ruby
class ItemTag < ApplicationRecord
  acts_as_tenant :account

  belongs_to :shop
  belongs_to :created_by, class_name: "Shopkeeper"
  belongs_to :completed_by, class_name: "Shopkeeper", optional: true

  enum :state, { idled: 0, completed: 1 }

  validates :name, presence: true

  scope :completed_order, -> { where(state: :completed).order(completed_at: :desc) }
  # Add other generic scopes as needed
end
```

### 6.2 Commit

```bash
git add app/models/item_tag.rb
git commit -m "Refactor ItemTag model for generic CRUD"
```

---

## Step 7: Update Shop model

### 7.1 Edit `app/models/shop.rb`

**Remove**:
- `def latest_completed_item_tag` (queue-specific; verify no callers first)
- `def create_default_item_tags!` (generates A001-A010 queue numbers)
- `def reset!` (queue-specific bulk reset)
- `def full_reload_entire_page` (turbo_stream broadcast; verify no external callers)

**Replace** `after_create :create_default_item_tags!` with `after_create :create_sample_item_tag`.

**Add** new method `create_sample_item_tag` (generic default item for first-run UX).

**Keep**:
- `acts_as_tenant :account`
- `belongs_to :created_by, class_name: "Shopkeeper"`
- `has_many :item_tags, dependent: :destroy`
- `validates :name, presence: true`
- `validate :limit_count, on: :create`
- `limit_count` private method

Expected end state:

```ruby
class Shop < ApplicationRecord
  acts_as_tenant :account

  belongs_to :created_by, class_name: "Shopkeeper"
  has_many :item_tags, dependent: :destroy

  validates :name, presence: true
  validate :limit_count, on: :create

  after_create :create_sample_item_tag

  private

  def create_sample_item_tag
    item_tags.create!(
      name: "Sample",
      description: "This is a sample. You can update or delete it.",
      created_by: created_by
    )
  rescue => e
    # Don't fail Shop creation if sample creation fails
    Rails.logger.warn "Failed to create sample item_tag for Shop #{id}: #{e.message}"
  end

  def limit_count
    ActsAsTenant.without_tenant do
      the_limit_count = ConfigSettings.shop.limit_count
      return if created_by.created_shops.count < the_limit_count
      errors.add :base, :limit_count_shop, limit_count: the_limit_count
    end
  end
end
```

**Rationale for sample item**: When a Shop is first created, the Shop detail screen would otherwise be empty. A single generic "Sample" item gives users a reference to understand the UI and something to delete/edit to learn the flow. The client-side empty state UI (already implemented) handles the case after the sample is deleted.

Check callers of removed methods:

```bash
git grep -n "latest_completed_item_tag\|create_default_item_tags\|full_reload_entire_page\|shop\.reset!"
```

Remove each caller's invocation as well.

### 7.2 Commit

```bash
git add app/models/shop.rb
git commit -m "Simplify Shop model: replace queue auto-generation with single sample item"
```

---

## Step 8: Update ItemTag controller

### 8.1 Edit `app/controllers/api/v1/shopkeeper/item_tags_controller.rb`

**Remove**:
- Any action related to `scan_tag!`, `reset_all`, queue-specific logic
- Filter on `queue_number`, `scan_state`, etc.

**Ensure standard CRUD actions work**:
- `index` — list item_tags for a shop
- `show` — single item_tag
- `create` — requires `name`, accepts optional `description`, `position`
- `update` — modify `name`, `description`, `position`, `state`
- `destroy` — delete
- `complete` / `idle` — state transition actions (if current code has them, keep them as generic state toggles)

**Strong parameters**:
```ruby
def item_tag_params
  params.require(:item_tag).permit(:name, :description, :position, :state)
end
```

### 8.2 Commit

```bash
git add app/controllers/api/v1/shopkeeper/item_tags_controller.rb
git commit -m "Update ItemTag controller for new schema"
```

---

## Step 9: Update ItemTag serializer

### 9.1 Edit `app/serializers/item_tag_serializer.rb`

Replace `queue_number` with `name`. Add `description` and `position`. Remove `scan_state`, `customer_read_at`, `already_completed`.

```ruby
class ItemTagSerializer
  include JSONAPI::Serializer

  attributes :name, :description, :position, :state, :completed_at,
             :created_at, :updated_at

  belongs_to :shop
  belongs_to :created_by, serializer: ShopkeeperSerializer
  belongs_to :completed_by, serializer: ShopkeeperSerializer, optional: true
end
```

(Adjust to match the actual serializer DSL in use — this may be `jsonapi-serializer`, `active_model_serializers`, or custom.)

### 9.2 Update Shop serializer

Remove any attribute referencing `latest_completed_item_tag` or `item_tags_count` if those were queue-specific.

### 9.3 Commit

```bash
git add app/serializers/
git commit -m "Update serializers for new ItemTag schema"
```

---

## Step 10: Update Pundit policies

### 10.1 Edit `app/policies/api/shopkeeper/item_tag_policy.rb`

ItemTag is a child resource of Shop. In this substrate, there are no separate ItemTag permissions — ItemTag operations are authorized via Shop permissions. This matches modern collaborative SaaS (Notion, Linear, Trello) where parent permissions implicitly apply to children.

Mapping:
- `read_data` → index, show
- `update_shops` → create, update, destroy, state toggle (complete/idle)

Expected policy:

```ruby
class Api::Shopkeeper::ItemTagPolicy < Api::Shopkeeper::BasePolicy
  def index?
    shopkeeper.has_permission?("read_data")
  end

  def show?
    shopkeeper.has_permission?("read_data")
  end

  def create?
    shopkeeper.has_permission?("update_shops")
  end

  def update?
    shopkeeper.has_permission?("update_shops")
  end

  def destroy?
    shopkeeper.has_permission?("update_shops")
  end

  # State toggle actions (if the controller has complete / idle custom actions)
  def complete?
    shopkeeper.has_permission?("update_shops")
  end

  def idle?
    shopkeeper.has_permission?("update_shops")
  end
end
```

(Adjust method names to match the actual controller actions and base policy class structure.)

Also check other policies for references to removed permission tags and replace with the new permission set:

```bash
grep -rn "manage_tags\|write_info_to_tags\|reset_all_tags\|complete_or_reset_tags\|show_tag_info" app/policies/
```

Any match must be replaced with `update_shops` or `read_data` as appropriate, or the method removed if it was queue-specific.

### 10.2 Verify

```bash
grep -rn "manage_tags\|write_info_to_tags\|reset_all_tags\|complete_or_reset_tags\|show_tag_info" app/policies/
# Expected: empty
```

### 10.3 Commit

```bash
git add app/policies/
git commit -m "Update ItemTag policy: use Shop permissions (read_data, update_shops)"
```

---

## Step 11: Update madmin resource for ItemTag

### 11.1 Edit `app/madmin/resources/item_tag_resource.rb`

Replace `queue_number` with `name`. Add `description`, `position`. Remove `scan_state`, `customer_read_at`, `already_completed`.

### 11.2 Commit

```bash
git add app/madmin/resources/item_tag_resource.rb
git commit -m "Update madmin resource for new ItemTag schema"
```

---

## Step 12: Redesign Role and Permission fixtures

### 12.1 Edit fixture files

For each environment (`development`, `test`, `staging`, `production`):

**`db/fixtures/<env>/01_permissions.rb`** — replace with:

```ruby
[
  {name: "create shops", tag: "create_shops", position: 1},
  {name: "update shops", tag: "update_shops", position: 2},
  {name: "delete shops", tag: "delete_shops", position: 3},
  {name: "update organizations", tag: "update_organizations", position: 4},
  {name: "invitation", tag: "invitation", position: 5},
  {name: "read data", tag: "read_data", position: 6}
].each do |attrs|
  Permission.find_or_create_by!(tag: attrs[:tag]) do |p|
    p.name = attrs[:name]
    p.position = attrs[:position]
  end
end
```

(Adjust to match the existing fixture's style — `find_or_create_by!` vs direct assignment.)

**`db/fixtures/<env>/02_roles.rb`** — replace with:

```ruby
[
  {name: "admin", tag: "admin", position: 1},
  {name: "member", tag: "member", position: 2}
].each do |attrs|
  Role.find_or_create_by!(tag: attrs[:tag]) do |r|
    r.name = attrs[:name]
    r.position = attrs[:position]
  end
end
```

(Check whether the current `Role` model has `tag` and `position` fields; adjust accordingly.)

**`db/fixtures/<env>/03_roles_permissions.rb`** — replace with:

```ruby
admin_role = Role.find_by!(tag: "admin")
member_role = Role.find_by!(tag: "member")

create_shops_perm = Permission.find_by!(tag: "create_shops")
update_shops_perm = Permission.find_by!(tag: "update_shops")
delete_shops_perm = Permission.find_by!(tag: "delete_shops")
update_orgs_perm = Permission.find_by!(tag: "update_organizations")
invitation_perm = Permission.find_by!(tag: "invitation")
read_data_perm = Permission.find_by!(tag: "read_data")

mappings = [
  # Admin: all permissions
  {role: admin_role, permission: create_shops_perm},
  {role: admin_role, permission: update_shops_perm},
  {role: admin_role, permission: delete_shops_perm},
  {role: admin_role, permission: update_orgs_perm},
  {role: admin_role, permission: invitation_perm},
  {role: admin_role, permission: read_data_perm},

  # Member: CRUD on shops + read, but NOT organization management or invitation
  {role: member_role, permission: create_shops_perm},
  {role: member_role, permission: update_shops_perm},
  {role: member_role, permission: delete_shops_perm},
  {role: member_role, permission: read_data_perm}
]

mappings.each do |m|
  RolesPermission.find_or_create_by!(role_id: m[:role].id, permission_id: m[:permission].id)
end
```

### 12.2 Verify

```bash
bin/rails db:drop db:create db:migrate
<fixture load command>

bin/rails runner "puts Permission.pluck(:tag).sort"
# Expected: create_shops, delete_shops, invitation, read_data, update_organizations, update_shops

bin/rails runner "puts Role.pluck(:tag).sort"
# Expected: admin, member

bin/rails runner "
  admin = Role.find_by(tag: 'admin')
  puts 'Admin permissions: ' + admin.permissions.pluck(:tag).sort.join(', ')
  member = Role.find_by(tag: 'member')
  puts 'Member permissions: ' + member.permissions.pluck(:tag).sort.join(', ')
"
```

### 12.3 Commit

```bash
git add db/fixtures/
git commit -m "Redesign roles (admin/member) and permissions (generic CRUD)"
```

---

## Step 13: Audit rolified.rb concern

### 13.1 Check for hard-coded role/permission tags

```bash
cat app/models/concerns/rolified.rb
```

If the concern hard-codes tag names:
- `senior_manager`, `junior_manager`, etc. → update to `admin`, `member`
- Queue permission tags → replace with new generic ones

Update methods accordingly. Common patterns:

```ruby
def admin?
  role&.tag == "admin"
end

def member?
  role&.tag == "member"
end

def has_permission?(tag)
  role&.permissions&.exists?(tag: tag)
end
```

### 13.2 Commit

```bash
git add app/models/concerns/rolified.rb
git commit -m "Update rolified concern for admin/member roles"
```

---

## Step 14: Update locales

### 14.1 Edit `config/locales/en.yml` (and `ja.yml` if present)

Remove translation keys for deleted permissions and roles:
- `activerecord.attributes.permission.tag.manage_tags`
- `activerecord.attributes.role.tag.senior_manager`
- etc.

Add translations for new permissions:
- `create_shops`, `delete_shops` (new additions)

Adjust for the simplified role set.

### 14.2 Commit

```bash
git add config/locales/
git commit -m "Update locales for new role/permission set"
```

---

## Step 15: Update tests

### 15.1 Fix model tests

```bash
bin/rails test 2>&1 | tee /tmp/p1-test-output.txt
```

Expect failures. Fix them:

**`test/models/item_tag_test.rb`**:
- Replace `queue_number` assertions with `name`
- Remove assertions on `scan_state`, `customer_read_at`, `already_completed`
- Add tests for `name` presence validation, `description`, `position`

**`test/models/shop_test.rb`**:
- Remove tests for `create_default_item_tags!`, `reset!`, `latest_completed_item_tag`, `full_reload_entire_page`
- **Add test for the new `create_sample_item_tag` callback**:

```ruby
test "creates a sample item_tag after create" do
  shop = Shop.create!(name: "Test Shop", account: accounts(:one), created_by: shopkeepers(:one))
  assert_equal 1, shop.item_tags.count
  sample = shop.item_tags.first
  assert_equal "Sample", sample.name
  assert_not_nil sample.description
  assert_equal "idled", sample.state
end

test "Shop creation does not fail if sample item_tag creation fails" do
  # Simulate failure by making item_tags invalid
  Shop.any_instance.stubs(:create_sample_item_tag).raises(StandardError, "mocked failure")
  # If the rescue in the method works, Shop should still be created
  # ... or test the rescue branch another way
end
```

(Adjust to match the existing test style — `test_helper.rb` config, fixtures, mocking library.)

**`test/controllers/api/v1/shopkeeper/item_tags_controller_test.rb`**:
- Update fixture data references (`queue_number` → `name`)
- Remove tests for removed endpoints (scan, reset_all)
- Add tests for `description`, `position` handling
- Note: tests that create a Shop will now also create a sample ItemTag via the callback. Adjust `assert_difference` expectations: creating a Shop now creates 1 Shop + 1 ItemTag.

**`test/policies/api/shopkeeper/item_tag_policy_test.rb`**:
- Remove tests for deleted permission tags
- Update role references (senior_manager → admin, junior_manager → member, etc.)

**Fixtures** (`test/fixtures/`):
- `item_tags.yml`: rename `queue_number:` → `name:`, add `description:` and `position:` if desired, remove queue-specific fields
- `roles.yml`: adjust to 2 roles
- `permissions.yml`: adjust to 6 permissions
- `roles_permissions.yml`: adjust mappings

### 15.2 Run tests iteratively

```bash
# Run specific test files as you fix them
bin/rails test test/models/item_tag_test.rb
bin/rails test test/models/shop_test.rb
bin/rails test test/controllers/api/v1/shopkeeper/item_tags_controller_test.rb

# Full suite once individual fixes are in
bin/rails test
```

### 15.3 Commit

Ideally split into multiple commits:

```bash
git add test/fixtures/
git commit -m "Update test fixtures for new ItemTag schema"

git add test/models/
git commit -m "Update model tests for refactored schema"

git add test/controllers/
git commit -m "Update controller tests for refactored API"

git add test/policies/
git commit -m "Update policy tests for admin/member roles"
```

---

## Step 16: Documentation cleanup

### 16.1 Update README

```bash
grep -n "queue\|NFC\|QR\|Number Tag\|ItemTag" README.md
```

Rewrite references to describe the substrate as a generic CRUD template, not a queue app.

### 16.2 Update CLAUDE.md

Similar to README. This file guides Claude Code on project context.

### 16.3 Update OpenAPI spec

```bash
cat docs/openapi.yaml | grep -nE "queue|scan|NFC"
```

Remove references to deleted endpoints and fields. Update `ItemTag` schema to reflect new columns.

### 16.4 Remove queue-specific docs

```bash
[ -f docs/pagination-item-tags.md ] && git rm docs/pagination-item-tags.md
# Review other docs in docs/ for queue-specific content
ls docs/
```

### 16.5 Commit

```bash
git add README.md CLAUDE.md docs/
git commit -m "Update documentation for generic CRUD substrate"
```

---

## Step 17: Final verification

### 17.1 Comprehensive grep for residuals

```bash
cd ~/pg/ruby/pg/nativeapptemplateapi

# Queue-specific column names (excluding historical migrations and CHANGELOG)
git grep -n "queue_number\|scan_state\|customer_read_at\|already_completed" \
  -- ':!db/migrate/' ':!CHANGELOG.md'
# Expected: empty

# NFC / QR references
git grep -in "nfc\|qr_code\|qrcode" \
  -- ':!CHANGELOG.md'
# Expected: empty

# Removed permission tags
git grep -n "manage_tags\|write_info_to_tags\|reset_all_tags\|complete_or_reset_tags\|show_tag_info" \
  -- ':!CHANGELOG.md' ':!db/migrate/'
# Expected: empty

# Removed role tags
git grep -n "senior_manager\|junior_manager\|senior_member\|junior_member" \
  -- ':!CHANGELOG.md' ':!db/migrate/'
# Expected: empty

# UI label leak (Rails views if any)
git grep -n "Number Tag" -- ':!CHANGELOG.md'
# Expected: empty

# Display namespace
git grep -n "Display::" -- ':!CHANGELOG.md'
# Expected: empty

# Scan routes
git grep -n "scan_customer\|'scan'" -- ':!CHANGELOG.md'
# Expected: empty
```

### 17.2 DB rebuild from clean state

```bash
bin/rails db:drop db:create db:migrate
<fixture load command>

bin/rails runner "
  puts 'Permissions: ' + Permission.count.to_s
  puts 'Roles: ' + Role.count.to_s
  puts 'Tables: ' + ActiveRecord::Base.connection.tables.sort.join(', ')
"
```

Expected:
- Permissions: 6
- Roles: 2
- No `item_tags` columns beyond the new schema

### 17.3 Full test run

```bash
bin/rails test
```

Expected: all green, 0 failures, 0 errors. Test count will be lower than baseline (removed tests for deleted features).

### 17.4 Manual API check

```bash
bin/rails server -d

# Create a test shopkeeper and shop, then verify:
# - Creating a shop creates exactly 1 "Sample" item_tag automatically
# - The sample item_tag has state: "idled"
# - Manual CRUD on item_tags works

curl -X POST http://localhost:3000/api/v1/shopkeeper/shops/SHOP_ID/item_tags \
  -H "Content-Type: application/json" \
  -H "[auth headers]" \
  -d '{"item_tag": {"name": "Test item", "description": "A test item"}}'

curl http://localhost:3000/api/v1/shopkeeper/shops/SHOP_ID/item_tags \
  -H "[auth headers]"

kill $(cat tmp/pids/server.pid)
```

Verify:
- Create, list, update, delete all work
- Response uses `name` not `queue_number`
- First list includes the "Sample" item plus any manually-created items

### 17.5 Push

```bash
git log --oneline -30
git push origin main
```

---

## Phase 1 Completion Checklist

- [ ] All tests green (`bin/rails test` 0 failures, 0 errors)
- [ ] Schema shows `item_tags.name` (not `queue_number`), `item_tags.description`, `item_tags.position`
- [ ] `item_tags.scan_state`, `customer_read_at`, `already_completed` removed
- [ ] `Permission.count == 6`, `Role.count == 2`
- [ ] Shop creation auto-generates exactly 1 "Sample" ItemTag
- [ ] No `queue_number`, `scan_state`, etc. in `git grep` (excluding historical migrations)
- [ ] No `senior_manager`, `junior_manager`, etc. in `git grep`
- [ ] No `manage_tags`, `write_info_to_tags`, etc. in `git grep`
- [ ] `bin/rails routes` has no `scan`, `display`, or queue-related routes
- [ ] API CRUD on item_tags works via curl (uses `name`, accepts `description`/`position`)
- [ ] All commits pushed to `origin/main`
- [ ] Documentation updated (README, CLAUDE.md, OpenAPI)

---

## Common Pitfalls

### 1. Fixture file loading

This repo's `db/fixtures/<env>/` is NOT standard Rails seeds. Identify the custom rake task before running fixture-related commands. `bin/rails db:seed` likely does nothing useful.

### 2. `Shopkeeper::Accounts` concern

Check if this concern references any deleted role/permission tags:

```bash
cat app/models/concerns/shopkeeper/accounts.rb
grep -n "senior_manager\|junior_manager\|senior_member\|junior_member\|guest\|manage_tags" \
  app/models/concerns/shopkeeper/accounts.rb
```

Update if needed.

### 3. `turbo_stream` broadcasts

Shop's `full_reload_entire_page` may be called from non-obvious places (e.g. Turbo Stream channel subscriptions). After removing, run:

```bash
git grep -n "full_reload_entire_page"
```

Ensure zero results before declaring the method removed.

### 4. `completed_by_id` migration

The `20260409072237_change_shopkeeper_foreign_keys_to_nullify_on_delete.rb` migration adds `on_delete: :nullify` to `completed_by_id` and `created_by_id`. These columns are preserved in the new schema. Leave this historical migration alone.

### 5. Test data dependencies

`test/fixtures/shops.yml` may reference `item_tags` in associations. After changing `item_tags.yml`, run:

```bash
bin/rails test test/models/shop_test.rb
```

Early, to catch fixture association breakage.

### 6. Sample item_tag and test isolation

After the refactor, creating a Shop in tests auto-creates 1 ItemTag via `create_sample_item_tag`. Tests that count ItemTags must account for this:

```ruby
# Before: 0 item_tags after shop creation
# After: 1 item_tag after shop creation

assert_difference "ItemTag.count", 1 do
  Shop.create!(...)
end
```

Review existing tests for `assert_difference "ItemTag.count"` and similar patterns.

### 7. Position column and acts_as_list

Do NOT add `acts_as_list` gem in Phase 1. The `position` column is just an integer; reordering is client-side for now. Adding `acts_as_list` requires gem install, config, and callback integration — defer to a future phase if needed.

### 8. Madmin resource auto-generation

`app/madmin/resources/item_tag_resource.rb` may auto-list all columns. After schema change, verify the madmin UI loads without errors:

```bash
bin/rails server
# Visit http://localhost:3000/madmin/item_tags
```

### 9. `name` uniqueness

Do NOT add `validates :name, uniqueness: true` unless required. Many domains allow duplicate item names (e.g., two todos with "Buy milk"). Keep validation minimal.

### 10. Sample item creation failure handling

The `create_sample_item_tag` method uses `rescue` to avoid failing Shop creation if ItemTag creation fails. This is intentional — a missing sample is a soft failure (user just sees an empty state). But log failures so they're visible in production:

```ruby
Rails.logger.warn "Failed to create sample item_tag for Shop #{id}: #{e.message}"
```

---

## Rollback

If Phase 1 goes off the rails:

```bash
cd ~/pg/ruby/pg/nativeapptemplateapi
git checkout v1-with-nfc
```

This returns to the pre-refactor state. The `v1.0.0-with-nfc` tag is an immutable reference if needed.

---

## After Phase 1

Proceed to Phase 2 (iOS Paid refactor). Phase 2's detailed checklist will be created after Phase 1 completes, incorporating any learnings from this phase.

Check the overview doc (`nativeapptemplate-substrate-v2-overview.md`) for the full Phase 2-8 summary.
