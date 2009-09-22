class AddAutoAddOptionToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :auto_add_to_customer_tasks, :boolean
  end

  def self.down
    remove_column :users, :auto_add_to_customer_tasks
  end
end
