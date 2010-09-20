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

    #move email data from users table to email_adresses table
    execute("INSERT INTO email_addresses(`user_id`, `email`,`default`, `created_at`, `updated_at`)
             SELECT users.id, users.email, 1, users.created_at, users.updated_at from users")
    remove_column :users, :email
  end

  def self.down
    add_column :users, :email, :string

    execute("UPDATE users LEFT JOIN email_addresses ON users.id = email_addresses.user_id
             SET users.email = email_addresses.email WHERE email_addresses.default = 1")
    drop_table :email_addresses
  end
  
end
