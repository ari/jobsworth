class AddServiceIdToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :service_id, :integer
  end
end
