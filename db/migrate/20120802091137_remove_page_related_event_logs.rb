class RemovePageRelatedEventLogs < ActiveRecord::Migration
  def up
    EventLog.where(:target_type => 'Page').delete_all
  end

  def down
  end
end
