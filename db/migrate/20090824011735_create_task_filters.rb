class CreateTaskFilters < ActiveRecord::Migration
  def self.up
    create_table :task_filters do |t|
      t.string :name
      t.integer :company_id
      t.integer :user_id
      t.boolean :shared

      t.timestamps
    end

    add_index :task_filters, :user_id
    add_index :task_filters, :company_id
  end

  def self.down
    drop_table :task_filters
  end
end
