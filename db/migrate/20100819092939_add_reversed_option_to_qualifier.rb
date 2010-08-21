class AddReversedOptionToQualifier < ActiveRecord::Migration
  def self.up
    add_column :keywords, :reversed, :boolean, :default=>false
    add_column :task_filter_qualifiers, :reversed, :boolean, :default=>false
  end

  def self.down
    remove_column :keywords, :reversed
    remove_column :task_filter_qualifiers, :reversed
  end
end
