class RefactorItemTagToGenericCrud < ActiveRecord::Migration[8.1]
  def change
    remove_index :item_tags, name: "index_item_tags_on_queue_number"
    remove_index :item_tags, name: "index_item_tags_on_shop_id_and_queue_number"

    remove_column :item_tags, :scan_state, :integer, default: 1, null: false
    remove_column :item_tags, :customer_read_at, :datetime, precision: nil
    remove_column :item_tags, :already_completed, :boolean, default: false, null: false

    rename_column :item_tags, :queue_number, :name

    add_column :item_tags, :description, :text
    add_column :item_tags, :position, :integer

    add_index :item_tags, [:shop_id, :position]
  end
end
