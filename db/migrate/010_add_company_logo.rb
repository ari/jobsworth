class AddCompanyLogo < ActiveRecord::Migration
  def self.up
    add_column :customers, :binary_id, :integer
  end

  def self.down
    remove_column :customers, :binary_id
  end
end
