class TriggersDump < ActiveRecord::Migration
  def self.up
    # All the triggers stored up until this time need to be deleted
    Trigger.destroy_all
    Trigger::Action.destroy_all
  end

  def self.down
    # nothing to do
  end
end
