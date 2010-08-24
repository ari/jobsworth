class ChangeScmFileStatus < ActiveRecord::Migration
  def self.up
    execute "UPDATE `scm_files` SET state = 'D' WHERE `state` LIKE '%deleted%'"
    execute "UPDATE `scm_files` SET state = 'A' WHERE `state` LIKE '%added%'"
    execute "UPDATE `scm_files` SET state = 'M' WHERE `state` LIKE '%modified%'"
  end

  def self.down
    #this migration just fix malformed data, not need to revert
  end
end
