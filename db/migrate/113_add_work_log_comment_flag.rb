class AddWorkLogCommentFlag < ActiveRecord::Migration
  def self.up
    add_column :work_logs, :comment, :boolean, :default => false    
  end

  def self.down
    remove_column :work_logs, :comment
  end
end
