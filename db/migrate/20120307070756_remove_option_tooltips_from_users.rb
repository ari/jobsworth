class RemoveOptionTooltipsFromUsers < ActiveRecord::Migration
  def up
    remove_column :users, :option_tooltips
  end

  def down
  end
end
