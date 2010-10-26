class OptionHideTooltips < ActiveRecord::Migration
  def self.up
    add_column :users, :option_tooltips, :integer
    @users = User.all
    @users.each { |u| 
      u.option_tooltips = 1
      u.save
    }
  end

  def self.down
    remove_column :users, :option_tooltips
  end
end
