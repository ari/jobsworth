class FixInvalidEmailAddress < ActiveRecord::Migration
  def up
    # Delete duplicate unknown email, link related records to the same email address which belongs to a user.
    # If no record with the same email is linked to a user, then only keep the first unknown email and update related record links.
    EmailAddress.where(:user_id => nil).each do |ea|
      # find the record with the same email linked to a user
      link_record = EmailAddress.where(:email => ea.email).where("user_id IS NOT NULL").first
      # If not, find the first record with the same email
      link_record = EmailAddress.where(:email => ea.email).first unless link_record

      # if the link_record equals to current record, do nothing
      next if link_record == ea

      puts "merging (#{ea.id}, #{ea.email}) into (#{link_record.id}, #{link_record.email})."

      # update related record foreign key before delete
      ea.work_logs.each { |wl| link_record.work_logs << wl }
      ea.abstract_tasks.each { |t| link_record.abstract_tasks << t }

      # delete current record
      ea.destroy
    end
  end

  def down
  end
end
