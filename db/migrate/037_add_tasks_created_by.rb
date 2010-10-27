class AddTasksCreatedBy < ActiveRecord::Migration
  def self.up
    add_column :tasks, :creator_id, :integer
    Task.all.each do |t|
      t.creator_id = t.user_id
      t.save
    end
  end

  def self.down
    remove_column :tasks, :creator_id
  end
end
