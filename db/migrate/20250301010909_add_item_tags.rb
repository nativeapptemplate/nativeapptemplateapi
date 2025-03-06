class AddItemTags < ActiveRecord::Migration[7.1]
  def change
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

    add_foreign_key "item_tags", "accounts"
    add_foreign_key "item_tags", "shopkeepers", column: "completed_by_id"
    add_foreign_key "item_tags", "shopkeepers", column: "created_by_id"
    add_foreign_key "item_tags", "shops"
  end
end
