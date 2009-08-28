class CreateTaskFilters < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :task_filters do |t|
      t.string :name
      t.integer :company_id
      t.integer :user_id
      t.boolean :shared

      t.timestamps
    end

    foreign_key(:task_filters, :user_id, :users)
    foreign_key(:task_filters, :company_id, :companies)
  end

  def self.down
    drop_table :task_filters
  end
end
