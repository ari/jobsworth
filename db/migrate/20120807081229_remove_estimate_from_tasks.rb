class RemoveEstimateFromTasks < ActiveRecord::Migration
  def up
    remove_column :tasks, :estimate
  end

  def down
  end
end
