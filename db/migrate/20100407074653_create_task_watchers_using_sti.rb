class CreateTaskWatchersUsingSti < ActiveRecord::Migration
  def self.up
    add_column :task_users, :type, :string, :default=>'TaskOwner'
    say_with_time "Using sti for task_watchers and task_owners, change boolean owner to strign type" do
      TaskUser.all.each do |tu|
        if tu.owner.nil? or tu.owner?
          tu.type='TaskOwner'
        else
          tu.type='TaskWatcher'
        end
        tu.save!
      end
    end
    remove_column :task_users, :owner
  end

  def self.down
    add_column :task_users, :owner, :boolean, :default=>true
    say_with_time "Rollback from sti task_users.type to boolean flag task_users.owner" do
      TaskUser.all.each do |tu|
        if tu.type == 'TaskOwner'
          tu.owner=true
        else
          tu.owner=false
        end
        tu.save!
      end
    end
    remove_column :task_users, :type
  end
end
