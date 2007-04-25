#!/usr/bin/env ruby

#You might want to change this
ENV["RAILS_ENV"] ||= "development"

require File.dirname(__FILE__) + "/../../config/environment"

$running = true;
Signal.trap("TERM") do
  $running = false
end

while($running) do

  date = Time.now.utc.change(:min => 0) + 17.hours

  puts "Checking tasks between #{date} and #{date + 1.hours}"

  tasks = Task.find(:all, :conditions => ["due_at > ? AND due_at < ? AND completed_at IS NULL", date, date + 1.hours], :order => "company_id")

  if tasks.size > 0
    puts "Got reminders to send.. #{tasks.size} tasks."

    user_ids = []
    tasks.each do |t|
      if t.users.size > 0
        user_ids += t.users.collect { |u| u.id if u.receive_notifications.to_i > 0 }
      end
    end
    user_ids.uniq!
    puts "Users involved: " + user_ids.join(',')

    user_ids.each do |u|
      user = User.find(u)
      puts "Handling tasks for #{user.name} / #{user.company.name}"
      user_tasks = user.tasks.find(:all, :conditions => ["due_at > ? AND due_at < ? AND completed_at IS NULL", date, date + 1.hours], :order => 'project_id, name')

      user_tasks.each do | ut |
        puts "  #{ut.due_at} => #{ut.name}"
      end

#      Notifications::deliver_reminder(user_tasks, user)

    end
  end




  secs = ((Time.now.change(:min => 1) + 1.hour) - Time.now).to_i
  puts "Done... Sleeping for #{secs}s"

  sleep secs
end

