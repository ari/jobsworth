class AddUserCompanyIdIndex < ActiveRecord::Migration
  def self.up
    Company.all.each do |c|
      dupe_sql = "select username from users where company_id = #{ c.id }"
      dupe_sql += " group by username having count(*) > 1"

      users = c.users.all(:conditions => "username in (#{ dupe_sql })",
                          :order => "id asc")
      users.shift # first user gets to keep the name, so skip them
      users.each_with_index do |u, i|
        u.update_attribute(:username, "#{ u.username }_#{ i + 1 }")
      end
    end

    Company.connection.execute("drop index users_username_index on users")
    add_index :users, [ :username, :company_id ], :unique => true
  end

  def self.down
  end
end
