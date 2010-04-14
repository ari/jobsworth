class CreateAccessLevels < ActiveRecord::Migration
  def self.up
    create_table :access_levels do |t|
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :access_levels
  end
end
