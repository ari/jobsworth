class AddTimezone < ActiveRecord::Migration
  def self.up
    add_column :users, :time_zone, :string
    execute "update users set time_zone='Europe/Oslo'"

    tz = Timezone.get('Europe/Oslo')

    @users = User.all
    @users.each { |u| 
      u.time_zone = "Europe/Oslo"
      u.created_at = tz.local_to_utc(u.created_at) if u.created_at
      u.updated_at = tz.local_to_utc(u.updated_at) if u.updated_at
      u.last_login_at = tz.local_to_utc(u.last_login_at) if u.last_login_at
      u.save
    }


    @worklogs = WorkLog.all
    @worklogs.each { |w| 
      w.started_at = tz.local_to_utc(w.started_at) if w.started_at
      w.save
    }
      
    @tasks = Task.all
    @tasks.each { |t|
      t.created_at = tz.local_to_utc(t.created_at) if t.created_at
      t.updated_at = tz.local_to_utc(t.updated_at) if t.updated_at
      t.completed_at = tz.local_to_utc(t.completed_at) if t.completed_at
      t.due_at = tz.local_to_utc(t.due_at) if t.due_at
    }

    @projects = Project.all
    @projects.each { |p|
      p.created_at = tz.local_to_utc(p.created_at) if p.created_at
      p.updated_at = tz.local_to_utc(p.updated_at) if p.updated_at
    }
  end

  def self.down
    remove_column :users, :time_zone
  end
end
