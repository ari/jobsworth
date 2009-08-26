class CreatePreferences < ActiveRecord::Migration
  def self.up
    create_table :preferences do |t|
      t.integer :preferencable_id
      t.string :preferencable_type
      t.string :key
      t.string :value

      t.timestamps
    end

    add_index :preferences, [ :preferencable_id, :preferencable_type ]
  end

  def self.down
    drop_table :preferences
  end
end
