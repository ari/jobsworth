class AddNeedScheduleToUsers < ActiveRecord::Migration
  def change
    add_column :users, :need_schedule, :boolean
  end
end
