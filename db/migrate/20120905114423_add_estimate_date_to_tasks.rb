class AddEstimateDateToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :estimate_date, :datetime
  end
end
