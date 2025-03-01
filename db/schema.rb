# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_03_01_010909) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.uuid "owner_id", null: false
    t.boolean "personal", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_accounts_on_owner_id"
  end

  create_table "accounts_invitations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "invited_by_id"
    t.string "token", null: false
    t.string "name", null: false
    t.string "email", null: false
    t.jsonb "roles", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_accounts_invitations_on_account_id"
    t.index ["invited_by_id"], name: "index_accounts_invitations_on_invited_by_id"
    t.index ["token"], name: "index_accounts_invitations_on_token", unique: true
  end

  create_table "accounts_shopkeepers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "shopkeeper_id", null: false
    t.jsonb "roles", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_accounts_shopkeepers_on_account_id"
    t.index ["shopkeeper_id"], name: "index_accounts_shopkeepers_on_shopkeeper_id"
  end

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
  end

  create_table "app_versions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "platform", null: false
    t.integer "version", null: false
    t.integer "current_type", default: 1, null: false
    t.integer "forced_update_type", default: 1, null: false
    t.string "title", null: false
    t.text "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["platform", "version"], name: "index_app_versions_on_platform_and_version", unique: true
  end

  create_table "item_tags", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "shop_id", null: false
    t.uuid "created_by_id"
    t.uuid "completed_by_id"
    t.string "queue_number", null: false
    t.integer "state", default: 1, null: false
    t.datetime "customer_read_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "scan_state", default: 1, null: false
    t.boolean "already_completed", default: false, null: false
    t.index ["account_id"], name: "index_item_tags_on_account_id"
    t.index ["completed_by_id"], name: "index_item_tags_on_completed_by_id"
    t.index ["created_by_id"], name: "index_item_tags_on_created_by_id"
    t.index ["queue_number"], name: "index_item_tags_on_queue_number"
    t.index ["shop_id", "queue_number"], name: "index_item_tags_on_shop_id_and_queue_number", unique: true
    t.index ["shop_id"], name: "index_item_tags_on_shop_id"
    t.index ["state"], name: "index_item_tags_on_state"
  end

  create_table "permissions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "tag", null: false
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag"], name: "index_permissions_on_tag", unique: true
  end

  create_table "privacy_versions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "version", null: false
    t.integer "current_type", default: 1, null: false
    t.datetime "published_at", null: false
    t.string "title", null: false
    t.text "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["version"], name: "index_privacy_versions_on_version", unique: true
  end

  create_table "roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "tag", null: false
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag"], name: "index_roles_on_tag", unique: true
  end

  create_table "roles_permissions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "role_id", null: false
    t.uuid "permission_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["permission_id"], name: "index_roles_permissions_on_permission_id"
    t.index ["role_id", "permission_id"], name: "index_roles_permissions_on_role_id_and_permission_id", unique: true
    t.index ["role_id"], name: "index_roles_permissions_on_role_id"
  end

  create_table "shopkeepers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.boolean "allow_password_change", default: false
    t.datetime "remember_created_at", precision: nil
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.string "unconfirmed_email"
    t.string "name"
    t.string "nickname"
    t.string "image"
    t.string "email"
    t.json "tokens"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "locale", default: "en", null: false
    t.string "time_zone", default: "London", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "current_platform", default: "", null: false
    t.integer "confirmed_privacy_version", default: 1, null: false
    t.integer "confirmed_terms_version", default: 1, null: false
    t.index ["confirmation_token"], name: "index_shopkeepers_on_confirmation_token", unique: true
    t.index ["email"], name: "index_shopkeepers_on_email", unique: true
    t.index ["reset_password_token"], name: "index_shopkeepers_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_shopkeepers_on_uid_and_provider", unique: true
  end

  create_table "shops", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "created_by_id", null: false
    t.string "name", null: false
    t.string "time_zone", default: "London", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.index ["account_id"], name: "index_shops_on_account_id"
    t.index ["created_by_id"], name: "index_shops_on_created_by_id"
  end

  create_table "terms_versions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "version", null: false
    t.integer "current_type", default: 1, null: false
    t.datetime "published_at", null: false
    t.string "title", null: false
    t.text "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["version"], name: "index_terms_versions_on_version", unique: true
  end

  add_foreign_key "accounts", "shopkeepers", column: "owner_id"
  add_foreign_key "accounts_invitations", "accounts"
  add_foreign_key "accounts_invitations", "shopkeepers", column: "invited_by_id"
  add_foreign_key "accounts_shopkeepers", "accounts"
  add_foreign_key "accounts_shopkeepers", "shopkeepers"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "item_tags", "accounts"
  add_foreign_key "item_tags", "shopkeepers", column: "completed_by_id"
  add_foreign_key "item_tags", "shopkeepers", column: "created_by_id"
  add_foreign_key "item_tags", "shops"
  add_foreign_key "roles_permissions", "permissions"
  add_foreign_key "roles_permissions", "roles"
  add_foreign_key "shops", "accounts"
  add_foreign_key "shops", "shopkeepers", column: "created_by_id"
end
