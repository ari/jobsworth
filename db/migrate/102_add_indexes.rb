class AddIndexes < ActiveRecord::Migration
  def self.up
    add_index :sheets, :task_id
    add_index :sheets, :user_id
    add_index :wiki_references, :wiki_page_id
    add_index :monitorships, :user_id
    add_index :posts, :topic_id
    
    add_index :project_folders, :parent_id
    add_index :project_files, :project_folder_id
    add_index :project_files, :task_id
    
    add_index :notifications, :user_id
    add_index :notifications, :task_id
    
    add_index :tasks, :milestone_id
  end

  def self.down
    remove_index :tasks, :milestone_id

    remove_index :notifications, :task_id
    remove_index :notifications, :user_id
    
    remove_index :project_files, :task_id
    remove_index :project_files, :project_folder_id
    remove_index :project_folders, :parent_id
    
    remove_index :posts, :topic_id
    remove_index :monitorships, :user_id
    remove_index :wiki_references, :wiki_page_id
    remove_index :sheets, :user_id
    remove_index :sheets, :task_id
  end
end
