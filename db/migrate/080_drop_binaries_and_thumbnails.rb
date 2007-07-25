class DropBinariesAndThumbnails < ActiveRecord::Migration
  def self.up
    say_with_time "Dropping binary tables..." do
      drop_table :thumbnails
      drop_table :binaries
    end
  end

  def self.down
    raise IrreversibleMigration
  end
end
