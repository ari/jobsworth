class AddQualifiableColumnToTaskFilterQualifiers < ActiveRecord::Migration
  def self.up
    add_column :task_filter_qualifiers, :qualifiable_column, :string
  end

  def self.down
    remove_column :task_filter_qualifiers, :qualifiable_column
  end
end
