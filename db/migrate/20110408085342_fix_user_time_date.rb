class FixUserTimeDate < ActiveRecord::Migration
  def self.up
  change_column :users, :date_format, :string, :default => "%d/%m/%Y"
  change_column :users, :time_format, :string, :default => "%H:%M"
  end

  def self.down
    change_column :users, :date_format, :string
  change_column :users, :time_format, :string
  end
end
