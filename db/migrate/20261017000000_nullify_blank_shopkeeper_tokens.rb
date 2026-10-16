# Saving a shopkeeper in madmin stored "" in empty token fields; a second ""
# then broke the unique indexes. Shopkeeper now normalizes blanks to NULL, and
# this clears the "" already stored.
class NullifyBlankShopkeeperTokens < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE shopkeepers SET reset_password_token = NULL WHERE reset_password_token = ''"
    execute "UPDATE shopkeepers SET confirmation_token = NULL WHERE confirmation_token = ''"
  end

  def down
  end
end
