class FixDuplicateEmailAddresses < ActiveRecord::Migration
  def self.link_email_address(keep, to_delete)
    to_delete.work_logs.update_all(:email_address_id => keep.id)

    to_delete.tasks.each do |task|
      task.email_addresses.delete(to_delete)
      task.email_addresses << keep
    end

    to_delete.delete
  end

  def self.link_user(keep, to_delete)
    return if keep == to_delete

    EmailDelivery.where(:user_id => to_delete.id).update_all(:user_id => keep.id)
    EventLog.where(:user_id => to_delete.id).update_all(:user_id => keep.id)
    GeneratedReport.where(:user_id => to_delete.id).update_all(:user_id => keep.id)
    Locale.where(:user_id => to_delete.id).update_all(:user_id => keep.id)
    Milestone.where(:user_id => to_delete.id).update_all(:user_id => keep.id)
    ProjectFile.where(:user_id => to_delete.id).update_all(:user_id => keep.id)
    ScmChangeset.where(:user_id => to_delete.id).update_all(:user_id => keep.id)
    Snippet.where(:user_id => to_delete.id).update_all(:user_id => keep.id)
    Todo.where(:creator_id => to_delete.id).update_all(:creator_id => keep.id)
    Todo.where(:completed_by_user_id => to_delete.id).update_all(:completed_by_user_id => keep.id)
    WikiPage.where(:locked_by => to_delete.id).update_all(:locked_by => keep.id)
    WikiRevision.where(:user_id => to_delete.id).update_all(:user_id => keep.id)
    WorkLog.where(:user_id => to_delete.id).update_all(:user_id => keep.id)
    TaskUser.where(:user_id => to_delete.id).update_all(:user_id => keep.id)

    to_delete.reload.destroy
  end

  def up
    query = "SELECT email, COUNT(email) FROM email_addresses GROUP BY email HAVING ( COUNT(email) > 1 )"
    result = ActiveRecord::Base.connection.execute(query)
    result.each do |arr|
      email = arr[0]
      count = arr[1]

      puts "WARNING: #{count} email have the same address #{email}"

      users = EmailAddress.where(:email => email).collect {|ea| ea.user }.reject {|u| u.nil? }

      # if all are unknow, keep the newest email_address
      if users.size == 0
        email_addresses = EmailAddress.where(:email => email).order("created_at DESC").all
        keep = email_addresses.shift
        email_addresses.each {|ea| FixDuplicateEmailAddresses.link_email_address(keep, ea) }
      end

      # if one is linked to user, keep the email_addresses linked to user
      if users.size == 1
        email_addresses = EmailAddress.where(:email => email).order("created_at DESC").all
        keep = email_addresses.detect {|ea| ea.user.present? }
        email_addresses.delete(keep)
        email_addresses.each {|ea| FixDuplicateEmailAddresses.link_email_address(keep, ea) }
      end

      # if more than one email_address is linked to user(most likely different user)
      # keep the newest user, and the newest email_address
      if users.size > 1
        users = users.sort {|u1, u2| u1.created_at <=> u2.created_at}
        user_to_keep = users.pop

        # fix duplicate email addresses
        email_addresses = EmailAddress.where(:email => email).order("created_at DESC").all
        keep = email_addresses.shift
        email_addresses.each {|ea| FixDuplicateEmailAddresses.link_email_address(keep, ea) }
        keep.update_column(:user_id, user_to_keep.id)

        # fix duplicate users
        users.each {|user| FixDuplicateEmailAddresses.link_user(user_to_keep, user) }
      end
    end
  end

  def down
  end
end
