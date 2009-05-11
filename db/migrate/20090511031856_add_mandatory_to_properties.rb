class AddMandatoryToProperties < ActiveRecord::Migration
  def self.up
    add_column :properties, :mandatory, :boolean, :default => false
  end

  def self.down
    remove_column :properties, :mandatory
  end
end
