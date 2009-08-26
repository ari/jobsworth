class AddShoutsCompanyIdIndex < ActiveRecord::Migration
  def self.up
	  add_index :shouts, :company_id
  end

  def self.down
	  remove_index :shouts, :company_id
  end
end
