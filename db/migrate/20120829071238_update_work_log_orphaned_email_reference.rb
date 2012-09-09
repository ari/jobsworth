class UpdateWorkLogOrphanedEmailReference < ActiveRecord::Migration
  def up
    WorkLog.where(:user_id => nil).each do |wl|
       next unless wl.email_address.try(:user)
       wl.update_attributes(:user_id => wl.email_address.user.id, :email_address_id => nil)
    end
  end

  def down
  end
end
