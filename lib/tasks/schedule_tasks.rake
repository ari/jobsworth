namespace :jobsworth do
  desc 'schedule tasks for all the open tasks'
  task :schedule => :environment do
    puts "schedule tasks for all the open tasks"
    User.all.each do |user|
      puts "schedule task for user #{user.name}"
      user.schedule_tasks
    end
    puts "Done."
  end
end

