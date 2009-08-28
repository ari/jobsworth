class CreateIcalEntries < ActiveRecord::Migration
  def self.up
    create_table :ical_entries do |t|
      t.column :task_id, :integer
      t.column :work_log_id, :integer
      t.column :body, :text
    end

    add_index :ical_entries, :task_id
    add_index :ical_entries, :work_log_id
  end

  def self.down
    remove_index :ical_entries, :task_id
    remove_index :ical_entries, :work_log_id
    drop_table :ical_entries
  end
end
