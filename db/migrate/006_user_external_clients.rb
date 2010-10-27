class UserExternalClients < ActiveRecord::Migration
  def self.up
    add_column :users, :option_externalclients, :integer
    @users = User.all
    @users.each { |u| 
      u.option_externalclients = 1
      u.save
    }
  end

  def self.down
    remove_column :users, :option_externalclients
  end
end
