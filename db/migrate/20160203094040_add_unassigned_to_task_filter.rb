class AddUnassignedToTaskFilter < ActiveRecord::Migration
  def change
    add_column :task_filters, :unassigned, :boolean
  end
end
