class AddFilterBySeverityPriority < ActiveRecord::Migration
  def self.up
    add_column :views, :filter_severity, :integer, :default => -10
    add_column :views, :filter_priority, :integer, :default => -10

    execute("UPDATE views SET filter_severity=-10, filter_priority=-10")

  end

  def self.down
    remove_column :views, :filter_priority
    remove_column :views, :filter_severity
  end
end
