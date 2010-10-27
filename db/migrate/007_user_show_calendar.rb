class UserShowCalendar < ActiveRecord::Migration
  def self.up
    add_column :users, :option_showcalendar, :integer
    @users = User.all
    @users.each { |u| 
      u.option_showcalendar = 1
      u.save
    }
  end

  def self.down
    remove_column :users, :option_showcalendar
  end
end
