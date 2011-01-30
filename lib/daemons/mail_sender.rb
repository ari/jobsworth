#!/usr/bin/env ruby

#You might want to change this
#ENV["RAILS_ENV"] ||= "development"

require File.dirname(__FILE__) + "/../../config/environment"

$running = true
Signal.trap("TERM") do
  $running = false
end

def grabuser(tasks, user_tasks, user_ids)
  tasks.each do |t|
    t.users.each do |u|
      if u.receive_notifications.to_i > 0
        user_ids.push(u.id)
        user_tasks[u.id] ||= []
        user_tasks[u.id].push(t)
      end
    end
  end 
end         

while($running) do

  date = Time.now.utc.change(:min => 0) + 16.hours

  puts "Checking tasks between #{date} and #{date + 1.hours}"

  tasks = Task.where("due_at > ? AND due_at < ? AND completed_at IS NULL", date, date + 1.hours).order("company_id")
  tasks_tomorrow = Task.where("due_at > ? AND due_at < ? AND completed_at IS NULL", date + 1.day, date + 1.hours + 1.day).order("company_id")
  tasks_overdue = Task.where("time(due_at) = time(?) AND due_at < ? AND due_at > ? AND completed_at IS NULL", date.change(:min => 59), date, 1.month.ago.utc).order("company_id, due_at")
                   
  user_ids = []      
  user_tasks = {}
  user_tasks_overdue = {}
  user_tasks_tomorrow = {}
  
  grabuser(tasks_overdue, user_tasks_overdue, user_ids)
  grabuser(tasks_tomorrow, user_tasks_tomorrow, user_ids)
  grabuser(tasks, user_tasks, user_ids)
 
  user_ids = user_ids.compact.uniq
  puts "Processing #{user_ids.size.to_s} users"
  
  user_ids.each do |u|
    user = User.find(u)
    puts "Handling tasks for #{user.name} / #{user.company.name}"
    
    begin
      Notifications::reminder(user_tasks[u], user_tasks_tomorrow[u], user_tasks_overdue[u], user).deliver
    rescue
      puts "  [#{user.id}] #{user.email} failed."
    end
  end

  secs = ((Time.now.change(:min => 1) + 1.hour) - Time.now).to_i
  puts "Done... Sleeping for #{secs}s"

  sleep secs
end

