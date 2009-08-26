class CreateEventLogs < ActiveRecord::Migration
  def self.up
    create_table :event_logs do |t|
      t.integer :company_id
      t.integer :project_id
      t.integer :user_id
      t.integer :event_type
      t.string  :target_type
      t.integer :target_id
      t.string  :title
      t.text    :body
      t.timestamps
    end

    add_index :event_logs, [:company_id, :project_id]
    add_index :event_logs, [:target_id, :target_type]
  end

  def self.down
    drop_table :event_logs
  end
end
