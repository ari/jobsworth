class ChangeTriggerActionType < ActiveRecord::Migration
  def self.up
    remove_column :triggers, :action
    add_column :triggers, :action_id, :integer
  end

  def self.down
    remove_column :triggers, :action_id
    add_column :triggers, :action, :string
  end
end
