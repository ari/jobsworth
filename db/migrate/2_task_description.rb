class TaskDescription < ActiveRecord::Migration
  def self.up
    add_column :tasks, :description,    :text
  end

  def self.down
    remove_column :tasks, :description
  end
end
