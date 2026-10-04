class AddUniqueIndexesBackingValidations < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :accounts_shopkeepers, [:account_id, :shopkeeper_id], unique: true, algorithm: :concurrently, if_not_exists: true
    add_index :accounts_invitations, [:account_id, :email], unique: true, algorithm: :concurrently, if_not_exists: true
  end
end
