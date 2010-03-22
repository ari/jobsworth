class FixPropertyPosition < ActiveRecord::Migration
  def self.up
    Company.all.each{|c| c.properties.each{|p| p.property_values.each_with_index{|pv, index| pv.position=index; pv.save! }}}
    change_column :property_values, :position, :integer, :null=>false
  end

  def self.down
    change_column :property_values, :postion, :integer, :null=>true
  end
end
