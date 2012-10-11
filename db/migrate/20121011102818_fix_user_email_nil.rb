class FixUserEmailNil < ActiveRecord::Migration
  def up
    User.all.each do |u|
      next unless u.email.nil?

      if u.email_addresses.count == 0
        puts "Error: user #{u.name} doesn't have any email address. Skipped."
        next
      end

      print "Fix user #{u.name}..."
      ed = u.email_addresses.first
      ed.default = true
      ed.save
      puts "\tDONE!"
    end
  end

  def down
  end
end
