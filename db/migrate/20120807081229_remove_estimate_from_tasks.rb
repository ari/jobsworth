class RemoveEstimateFromTasks < ActiveRecord::Migration
  def up
    # in some existing systems, the field `estimate` doesn't exist
    remove_column :tasks, :estimate rescue nil
  end

  def down
  end
end
