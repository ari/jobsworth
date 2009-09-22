class CreateTriggers < ActiveRecord::Migration
  def self.up
    create_table :triggers do |t|
      t.integer :company_id
      t.integer :task_filter_id
      t.text :fire_on
      t.string :action

      t.timestamps
    end
  end

  def self.down
    drop_table :triggers
  end
end
