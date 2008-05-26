class FixRestoreFromArchiveEvents < ActiveRecord::Migration
  def self.up
    execute("UPDATE event_logs set event_type=16 where target_type='WorkLog' and event_type=14;")
  end

  def self.down
    execute("UPDATE event_logs set event_type=14 where target_type='WorkLog' and event_type=16;")
  end
end
