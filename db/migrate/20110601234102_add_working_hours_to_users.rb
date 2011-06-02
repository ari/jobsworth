class AddWorkingHoursToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :working_hours, 
                       :string, 
                       :null    => false, 
                       :default => "8.0|8.0|8.0|8.0|8.0|0.0|0.0"
  end

  def self.down
    remove_column :users, :working_hours
  end
end
