require "migration_helpers"

class CreateTaskCustomers < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :task_customers do |t|
      t.integer :customer_id
      t.integer :task_id

      t.timestamps
    end

    foreign_key :task_customers, :task_id, :tasks
    foreign_key :task_customers, :customer_id, :customers
  end

  def self.down
    drop_table :task_customers
  end
end
