class CreateTodos < ActiveRecord::Migration
  def self.up
    create_table :todos do |t|
      t.integer   :task_id
      t.string    :name
      t.integer   :position
      t.integer   :creator_id
      t.timestamp :completed_at
      t.timestamps
    end

    add_index :todos, :task_id
  end

  def self.down
    drop_table :todos
  end
end
