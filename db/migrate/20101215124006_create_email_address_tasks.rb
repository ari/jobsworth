class CreateEmailAddressTasks < ActiveRecord::Migration
  def self.up
    create_table :email_address_tasks, :id=>false do |t|
      t.integer :task_id
      t.integer :email_address_id

      t.timestamps
    end
  end

  def self.down
    drop_table :email_address_tasks
  end
end
