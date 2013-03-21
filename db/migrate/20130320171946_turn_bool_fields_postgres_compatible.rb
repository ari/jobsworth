class TurnBoolFieldsPostgresCompatible < ActiveRecord::Migration
  def up
    add_column(:users, :receive_notifications_temp, :boolean, :default => true)
    User.reset_column_information
    User.find_each do |user|
      user.update_attribute( :receive_notifications_temp, ( user.receive_notifications == nil ? false : true ) )
    end
    remove_column( :users, :receive_notifications )
    rename_column( :users, :receive_notifications_temp, :receive_notifications )
  end

  def down
    add_column(:users, :receive_notifications_temp, :integer, :default => 1)
    User.reset_column_information
    User.find_each do |user|
      user.update_attribute( :receive_notifications_temp, ( user.receive_notifications == false ? nil : 1 ) )
    end
    remove_column( :users, :receive_notifications )
    rename_column( :users, :receive_notifications_temp, :receive_notifications )
  end
end
