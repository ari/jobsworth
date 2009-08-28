require "migration_helpers"

class AddForeignKeysForCustomers < ActiveRecord::Migration
  extend MigrationHelpers

  TABLES = {
    :customers => [ :activities, :organizational_units, :project_files,
                    :projects, :users, :work_logs ]
  }

  def self.up
    add_foreign_keys_for(TABLES)
  end

  def self.down
    remove_foreign_keys_for(TABLES)
  end
end
