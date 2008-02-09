#!/usr/bin/env ruby

#You might want to change this
#ENV["RAILS_ENV"] ||= "development"

require File.dirname(__FILE__) + "/../../config/environment"

$running = true;
Signal.trap("TERM") do
  $running = false
end

def grabuser(tasks, user_tasks, user_ids)
  tasks.each do |t|
    t.users.each do |u|
      if u.receive_notifications.to_i > 0
        user_ids.push(u.id)
        if !user_tasks.key?(u.id)
          user_tasks[u.id] = []
        end                                 
        user_tasks[u.id].push(t)
      end
    end
  end 
end         

while($running) do

  date = Time.now.utc.change(:min => 0) + 16.hours

  puts "Checking tasks between #{date} and #{date + 1.hours}"

  tasks = Task.find(:all, :conditions => ["due_at > ? AND due_at < ? AND completed_at IS NULL", date, date + 1.hours], :order => "company_id")
  tasks_tomorrow = Task.find(:all, :conditions => ["due_at > ? AND due_at < ? AND completed_at IS NULL", date + 1.day, date + 1.hours + 1.day], :order => "company_id")
  tasks_overdue = Task.find(:all, :conditions => ["time(due_at) = time(?) and due_at < ? and completed_at IS NULL", date.change(:min => 59), date], :order => "company_id")
                   
  user_ids = []      
  user_tasks = {}
  user_tasks_overdue = {}
  user_tasks_tomorrow = {}
  
  grabuser(tasks_overdue, user_tasks_overdue, user_ids)
  grabuser(tasks_tomorrow, user_tasks_tomorrow, user_ids)
  grabuser(tasks, user_tasks, user_ids)
 
  puts "\n\n"
  user_ids = user_ids.compact.uniq
  puts "Found #{user_ids.size.to_s} users"
  
  user_ids.each do |u|
    user = User.find(u)
    puts "Handling tasks for #{user.name} / #{user.company.name}"
    if user_tasks_overdue.key?(u)
      user_tasks_overdue[u].each do |t|
        puts "Overdue: #{t.name}"
      end
    end
    
    if user_tasks_tomorrow.key?(u) 
      user_tasks_tomorrow[u].each do |t|
        puts "Due Tomorrow: #{t.name}"
      end
    end
    
    if user_tasks.key?(u)      
      user_tasks[u].each do |t|
        puts "Due Today: #{t.name}"
      end
    end
       
    begin
      Notifications::deliver_reminder(user_tasks[u], user_tasks_tomorrow[u], user_tasks_overdue[u], user)
    rescue
      puts "  [#{user.id}] #{user.email} failed."
    end
  end

  secs = ((Time.now.change(:min => 1) + 1.hour) - Time.now).to_i
  puts "Done... Sleeping for #{secs}s"

  sleep secs
end

