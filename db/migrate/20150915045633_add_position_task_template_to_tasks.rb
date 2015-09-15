class AddPositionTaskTemplateToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :position_task_template, :integer
  end
end
