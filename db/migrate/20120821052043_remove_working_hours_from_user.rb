class RemoveWorkingHoursFromUser < ActiveRecord::Migration
  def up
    remove_column :users, :working_hours
  end

  def down
  end
end
