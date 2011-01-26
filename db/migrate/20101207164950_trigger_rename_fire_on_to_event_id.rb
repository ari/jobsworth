class TriggerRenameFireOnToEventId < ActiveRecord::Migration
  def self.up
    remove_column :triggers, :fire_on
    add_column :triggers, :event_id, :integer
  end

  def self.down
    remove_column :triggers, :event_id
    add_column :triggers, :fire_on, :string
  end
end
