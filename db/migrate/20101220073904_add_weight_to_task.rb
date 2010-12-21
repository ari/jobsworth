class AddWeightToTask < ActiveRecord::Migration
  def self.up
    add_column :tasks, :weight, :integer, :default=>0
    add_column :tasks, :weight_adjustment, :integer, :default=>0
  end

  def self.down
    remove_column :tasks, :weight
    remove_column :tasks, :weight_adjustment
  end
end
