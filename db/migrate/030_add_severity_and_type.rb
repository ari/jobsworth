class AddSeverityAndType < ActiveRecord::Migration
  def self.up
    add_column :tasks, :severity_id, :integer, { :default => 0 }
    add_column :tasks, :type_id, :integer, { :default => 0 }
  end

  def self.down
    remove_column :tasks, :type_id
    remove_column :tasks, :severity_id
  end
end
