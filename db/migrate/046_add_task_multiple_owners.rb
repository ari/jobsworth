class AddTaskMultipleOwners < ActiveRecord::Migration
  def self.up
    create_table( :task_owners )  do |t|
      t.column :user_id, :integer
      t.column :task_id, :integer
    end

    Task.all.each do |t|
      unless t.old_owner.nil?
        to = TaskOwner.new
        to.user_id = t.user_id
        to.task_id = t.id
        to.save
      end
    end

  end

  def self.down
    drop_table :task_owners
  end
end
