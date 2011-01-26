class TriggerHasManyActions < ActiveRecord::Migration
  def self.up
    remove_column :triggers, :action_id
  end

  def self.down
    add_column :triggers, :action_id, :integer
  end
end
