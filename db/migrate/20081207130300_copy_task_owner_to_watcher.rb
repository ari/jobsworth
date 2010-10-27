# Copy all task creator users to the watcher list. That way if the task creator is sick of seeing update emails they can remove themselves from the watcher list.

class CopyTaskOwnerToWatcher < ActiveRecord::Migration
  def self.up
    say_with_time "Copying task creators to watchers." do 
      Task.all.each do |t|
        n = Notification.new(:user => t.creator, :task => t)
        n.save
      end
    end
  end

  def self.down
  end
end
