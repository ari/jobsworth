class RenameTaskToTaskRecord < ActiveRecord::Migration
  def up
    AbstractTask.where(:type => "Task").update_all(:type => "TaskRecord")
  end

  def down
  end
end
