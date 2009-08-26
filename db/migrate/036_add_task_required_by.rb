class AddTaskRequiredBy < ActiveRecord::Migration
  def self.up
    add_column :tasks, :requested_by, :string
  end

  def self.down
    remove_column :tasks, :requested_by
  end
end
