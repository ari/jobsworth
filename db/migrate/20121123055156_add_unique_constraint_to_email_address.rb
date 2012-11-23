class AddUniqueConstraintToEmailAddress < ActiveRecord::Migration
  def change
    add_index :email_addresses, [:email], :unique => true
  end
end
