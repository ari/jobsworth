class ChangeSupressedEmailAddressesToText < ActiveRecord::Migration
  def up
    change_column :companies, :suppressed_email_addresses, :text
  end

  def down
  end
end
