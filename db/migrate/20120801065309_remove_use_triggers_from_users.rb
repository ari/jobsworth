class RemoveUseTriggersFromUsers < ActiveRecord::Migration
  def up
    remove_column :users, :use_triggers
  end

  def down
    add_column :users, :use_triggers, :boolean, :default => false
  end
end
