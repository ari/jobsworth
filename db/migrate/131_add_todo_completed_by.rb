class AddTodoCompletedBy < ActiveRecord::Migration
  def self.up
    add_column :todos, :completed_by_user_id, :integer, :default => nil
  end

  def self.down
    remove_column :todos, :completed_by_user_id
  end
end
