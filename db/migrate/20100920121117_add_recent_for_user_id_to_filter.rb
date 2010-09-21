class AddRecentForUserIdToFilter < ActiveRecord::Migration
  def self.up
    add_column :task_filters, :recent_for_user_id, :integer, :default=>nil
  end

  def self.down
    remove_column :task_filters, :recent_for_user_id
  end
end
