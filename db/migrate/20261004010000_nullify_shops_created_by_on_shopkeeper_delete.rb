class NullifyShopsCreatedByOnShopkeeperDelete < ActiveRecord::Migration[8.1]
  # A shop in a team someone else owns outlives its creator, like item tags do
  def change
    change_column_null :shops, :created_by_id, true
    remove_foreign_key :shops, :shopkeepers, column: :created_by_id
    add_foreign_key :shops, :shopkeepers, column: :created_by_id, on_delete: :nullify
  end
end
