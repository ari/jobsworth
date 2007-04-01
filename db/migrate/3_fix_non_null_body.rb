class FixNonNullBody < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE `work_logs` CHANGE `body` `body` TEXT DEFAULT NULL"
  end

  def self.down
    execute "ALTER TABLE `work_logs` CHANGE `body` `body` TEXT NOT NULL"
  end
end
