class AddExternalWatchers < ActiveRecord::Migration
  def self.up
    add_column :tasks, :notify_emails, :string
  end

  def self.down
    remove_column :tasks, :notify_emails
  end
end
