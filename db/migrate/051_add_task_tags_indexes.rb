class AddTaskTagsIndexes < ActiveRecord::Migration
  def self.up
    add_index :task_tags, :tag_id
    add_index :task_tags, :task_id
  end

  def self.down
    remove_index :task_tags, :tag_id
    remove_index :task_tags, :task_id
  end
end
