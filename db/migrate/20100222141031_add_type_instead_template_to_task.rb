class AddTypeInsteadTemplateToTask < ActiveRecord::Migration
  def self.up
    remove_column :tasks, :template
    add_column :tasks, :type, :string, :default=>'Task'
  end

  def self.down
    remove_column :tasks, :type
    add_column :tasks, :template, :boolean, :default=>false
  end
end
