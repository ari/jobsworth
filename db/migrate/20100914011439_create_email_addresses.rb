class CreateEmailAddresses < ActiveRecord::Migration
  extend MigrationHelpers
  
  def self.up
    create_table :email_addresses do |t|
      t.integer :user_id
      t.string  :email
      t.boolean :default
      t.timestamps
    end
    foreign_key(:email_addresses, :user_id, :users)
    
    User.find(:all, :select => "id, email").each do |u|
      u.email_addresses.create(:email => u.read_attribute(:email), :default => true)
    end
    remove_column :users, :email
  end

  def self.down
    add_column :users, :email, :string
    EmailAddress.find(:all, :conditions => {:default => 1}).each do |e|
      e.user.update_attribute('email', e.email)
    end
    drop_table :email_addresses
  end
end
