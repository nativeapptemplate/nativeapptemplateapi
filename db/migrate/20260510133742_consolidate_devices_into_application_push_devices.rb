class ConsolidateDevicesIntoApplicationPushDevices < ActiveRecord::Migration[8.1]
  def up
    drop_table :devices

    drop_table :action_push_native_devices

    create_table :action_push_native_devices, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name
      t.string :platform, null: false
      t.string :token, null: false
      t.string :bundle_id
      t.datetime :last_active_at
      t.references :owner, polymorphic: true, type: :uuid
      t.timestamps
      t.index [:platform, :token], unique: true
    end
  end

  def down
    drop_table :action_push_native_devices

    create_table :action_push_native_devices do |t|
      t.string :name
      t.string :platform, null: false
      t.string :token, null: false
      t.references :owner, polymorphic: true
      t.timestamps
    end

    create_table :devices, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :bundle_id
      t.datetime :last_active_at
      t.string :platform, null: false
      t.uuid :shopkeeper_id, null: false
      t.string :token, null: false
      t.timestamps
      t.index [:platform, :token], unique: true
      t.index [:shopkeeper_id]
    end
    add_foreign_key :devices, :shopkeepers
  end
end
