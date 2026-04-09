class ChangeShopkeeperForeignKeysToNullifyOnDelete < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :item_tags, column: :completed_by_id
    remove_foreign_key :item_tags, column: :created_by_id

    add_foreign_key :item_tags, :shopkeepers, column: :completed_by_id, on_delete: :nullify
    add_foreign_key :item_tags, :shopkeepers, column: :created_by_id, on_delete: :nullify
  end

  def down
    remove_foreign_key :item_tags, column: :completed_by_id
    remove_foreign_key :item_tags, column: :created_by_id

    add_foreign_key :item_tags, :shopkeepers, column: :completed_by_id
    add_foreign_key :item_tags, :shopkeepers, column: :created_by_id
  end
end
