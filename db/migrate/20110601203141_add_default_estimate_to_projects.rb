class AddDefaultEstimateToProjects < ActiveRecord::Migration
  def self.up
    add_column :projects, :default_estimate, 
                          :decimal,
                          :precision => 5, 
                          :scale => 2, 
                          :default => 1.0
  end

  def self.down
    remove_column :projects, :default_estimate
  end
end
