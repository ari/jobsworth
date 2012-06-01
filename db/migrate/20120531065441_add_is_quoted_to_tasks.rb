class AddIsQuotedToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :isQuoted, :boolean, :default => false, :null => false
  end
end
