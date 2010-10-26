class UserInterfaceType < ActiveRecord::Migration
  def self.up
    add_column :users, :option_tracktime, :integer
    @users = User.all
    @users.each { |u| 
      u.option_tracktime = 1
      u.save
    }
  end

  def self.down
    remove_column :users, :option_tracktime
  end
end
