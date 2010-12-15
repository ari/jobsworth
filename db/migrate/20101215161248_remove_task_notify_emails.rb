class RemoveTaskNotifyEmails < ActiveRecord::Migration
  def self.up
    AbstractTask.where('notify_emails is not NULL and notify_emails != ""').all.each{ |task|
      task.notify_emails=task.attributes['notify_emails']
      task.save
    }
    remove_column :tasks, :notify_emails
  end

  def self.down
    add_column :tasks, :notify_emails, :string
  end
end
