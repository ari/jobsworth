class DeviseCreateUsers < ActiveRecord::Migration
  def self.up
    change_table(:users) do |t|
      t.database_authenticatable :null => false
      t.recoverable
      t.rememberable
      t.trackable

      # t.confirmable
      # t.lockable :lock_strategy => :failed_attempts, :unlock_strategy => :both
      # t.token_authenticatable

    end

    add_index :users, :reset_password_token, :unique => true
    remove_column :users,  :email
    # add_index :users, :confirmation_token,   :unique => true
    # add_index :users, :unlock_token,         :unique => true
  end

  def self.down
    remove_column :users,  :encrypted_password
    remove_column :users,  :password_salt
    remove_column :users,  :reset_password_token
    remove_column :users,  :remember_token
    remove_column :users,  :remember_created_at
    remove_column :users,  :sign_in_count
    remove_column :users,  :current_sign_in_at
    remove_column :users,  :last_sign_in_at
    remove_column :users,  :current_sign_in_ip
    remove_column :users,  :last_sign_in_ip
  end
end
