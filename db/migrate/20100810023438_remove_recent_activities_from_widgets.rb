class RemoveRecentActivitiesFromWidgets < ActiveRecord::Migration

  def self.up
    Widget.destroy_all(:name => _("Recent Activities"))
  end

  def self.down
    # You have to configure many things to raise Recent Activities Data
    raise ActiveRecord::IrreversibleMigration, "Can't recover the #{_("Recent Activities")} widget"
  end
  
end
