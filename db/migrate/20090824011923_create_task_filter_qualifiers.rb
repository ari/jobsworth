class CreateTaskFilterQualifiers < ActiveRecord::Migration
 extend MigrationHelpers

  def self.up
    create_table :task_filter_qualifiers do |t|
      t.integer :task_filter_id
      t.string :qualifiable_type
      t.integer :qualifiable_id

      t.timestamps
    end

    foreign_key(:task_filter_qualifiers, :task_filter_id, :task_filters)
  end

  def self.down
    drop_table :task_filter_qualifiers
  end
end
