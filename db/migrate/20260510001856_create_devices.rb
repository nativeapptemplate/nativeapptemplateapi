class CreateDevices < ActiveRecord::Migration[8.1]
  def change
    create_table :devices, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :shopkeeper, type: :uuid, null: false, foreign_key: true
      t.string :token, null: false
      t.string :platform, null: false
      t.string :bundle_id
      t.datetime :last_active_at

      t.timestamps
    end

    add_index :devices, [:platform, :token], unique: true
  end
end
