class AddDateFormatTimeFormatNotNullOnUsers < ActiveRecord::Migration
  def self.up
    change_column :users, :date_format, :string, :null => false
    change_column :users, :time_format, :string, :null => false
  end

  def self.down
  end
end
