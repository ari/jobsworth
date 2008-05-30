class AddCompanyMessagingOption < ActiveRecord::Migration
  def self.up
    add_column :companies, :show_messaging, :boolean, :default => true
  end

  def self.down
    remove_column :companies, :show_messaging
  end
end
