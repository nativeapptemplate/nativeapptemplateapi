# Admin-set override that unlocks every paid feature for a shopkeeper's
# accounts, changed only in /madmin (see Shopkeeper#feature_access_state)
class AddFeatureAccessStateToShopkeepers < ActiveRecord::Migration[8.1]
  def change
    add_column :shopkeepers, :feature_access_state, :integer, default: 1, null: false
    add_index :shopkeepers, :feature_access_state
  end
end
