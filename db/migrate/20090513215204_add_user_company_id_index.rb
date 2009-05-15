class AddUserCompanyIdIndex < ActiveRecord::Migration
  def self.up
    Company.connection.execute("drop index users_username_index on users")
    add_index :users, [ :username, :company_id ], :unique => true
  end

  def self.down
  end
end
