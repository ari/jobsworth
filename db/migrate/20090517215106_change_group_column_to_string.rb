class ChangeGroupColumnToString < ActiveRecord::Migration
  def self.up
    change_column(:views, :auto_group, :string, :limit => 255, :default => "0")
  end

  def self.down
  end
end
