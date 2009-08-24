class CreateTaskFilterQualifiers < ActiveRecord::Migration
 extend MigrationHelpers

  def self.up
    create_table :task_filter_qualifiers do |t|
      t.integer :task_filter_id
      t.string :qualifiable_type
      t.integer :qualifiable_id

      t.timestamps
    end

    add_index :task_filter_qualifiers, :task_filter_id
  end

  def self.down
    drop_table :task_filter_qualifiers
  end
end
