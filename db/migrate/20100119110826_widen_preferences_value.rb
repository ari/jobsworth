class WidenPreferencesValue < ActiveRecord::Migration
  def self.up
  	change_column :preferences, :value, :text
  end

  def self.down
	change_column :preferences, :value, :string, :limit => 255
  end
end
