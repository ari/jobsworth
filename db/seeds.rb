if Rails.env != 'staging'
  puts "This seeder should be runned only in staging, but you're in #{Rails.env} environment, exiting seeder without changes to database."
elsif !Company.count.zero?
  puts "Database isn't clean. Clean up it, if you sure, using `RAILS_ENV=staging rake db:schema:load`"
else
  puts "This seeder will drop your existed database and create large amount of data"
  require "#{Rails.root}/test/blueprints"
  puts "create company"
  company=Company.make(:subdomain=>'jobsworth')

  puts "create 3k customers"
  ActiveRecord::Base.transaction do
    3_000.times {|i| Customer.make(:company=>company, :name=>Faker::Name.name+i.to_s)}
  end

  puts "create 1k users"
  ActiveRecord::Base.transaction do
    1_000.times { User.make(:company=>company)}
  end
  users=User.limit(100).all
  customers= Customer.limit(10).offset(100).all
  10.times    { |i| User.make(:company=>company, :customer=>customers[i])}

  admin=User.first
  admin.name='admin'
  admin.username='admin'
  admin.admin=true
  admin.password='password'
  admin.save!

  puts "create 30 projects"
  20.times { Project.make(:company=>company, :owner=>admin, :users=>[admin])}
  10.times { |i| Project.make(:company=>company, :customer=>customers[i], :owner=>admin, :users=>[admin]) }
  projects= Project.all
  puts "create 1k tasks, each with 10 work logs"
  1_000.times do |i|
    ActiveRecord::Base.transaction do
      owner=users[(i+1)%100]
      watcher= users[i%100]
      task=Task.make(:project=>projects[i%30], :customers=>[customers[i%10]], :watchers=>[watcher], :owners=>[owner])
      [owner, watcher].each do |user|
        3.times{ WorkLog.make(:task=>task, :user=>user, :project=>task.project, :customer=>task.project.customer)}
        2.times{ WorkLog.make(:task=>task, :user=>user,
                               :project=>task.project, :customer=>task.project.customer, :duration=>4.hours, :log_type=> EventLog::TASK_WORK_ADDED ) }
      end
    end
  end
  puts "done"
end
