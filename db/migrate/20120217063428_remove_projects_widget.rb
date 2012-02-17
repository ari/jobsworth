class RemoveProjectsWidget < ActiveRecord::Migration
  def up
    Widget.where(:widget_type => 1).destroy_all
  end

  def down
  end
end
