class CreateTriggerActions < ActiveRecord::Migration
  def self.up
    create_table :trigger_actions do |t|
      t.integer :trigger_id
      t.string  :name
      t.string  :type
      t.integer :argument
      t.timestamps
    end
  end

  def self.down
    drop_table :trigger_actions
  end
end
