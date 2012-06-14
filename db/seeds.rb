require "#{Rails.root}/test/blueprints"

def create_company
  puts "Creating company"
  company = Company.make(:subdomain=>'jobsworth')
  Customer.make(:company => company, :name => "Internal")
end

def create_customers(customer_num)
  puts "Creating #{customer_num} customers"
  company = Company.all.first
  ActiveRecord::Base.transaction do
    customer_num.times do |n|
      Customer.make(:company => company, :name => "#{Faker::Name.name}-#{n}")
    end
  end
end
  
def create_users(users_num)
  puts "Creating #{users_num} users"
  company = Company.all.first
  ActiveRecord::Base.transaction do
    users_num.times { User.make(:company => company) }
  end
end

def create_admin
  puts "Creating admin"
  admin = User.first
  admin.name     = 'admin'
  admin.username = 'admin'
  admin.admin    = true
  admin.password = 'password'
  admin.save!
end

def create_customer_users(num)
  customers = Customer.limit(num).offset(100).all
  company = Company.all.first
  num.times { |i| User.make(:company => company, :customer => customers[i])}
end

def create_projects(projects_num)
  puts "Creating #{projects_num} projects"
  company = Company.all.first
  customers = Customer.all(:limit => projects_num)
  admin     = User.where(admin).first
  projects_num.times do |i|
    Project.make(:company => company, :customer=>customers[i], :users=>[admin]) 
  end
end

def create_task(task_num)
  puts "Creating #{task_num} tasks"
  projects  = Project.all
  users     = User.all(:limit => 100)
  customers = Customer.limit(10).offset(100).all

  task_num.times do |i|
    owner    = users[(i+1)%100]
    watcher  = users[i%100]
    project  = projects[i%30]
    customer = [customers[i%10]]

    ActiveRecord::Base.transaction do
      task = Task.make(
        :company   => project.company,
        :project   => project, 
        :customers => customer, 
        :watchers  => [watcher], 
        :owners    => [owner]
      )

      create_work_log(task, watcher)
      create_work_log(task, owner)
    end
  end
end

def create_work_log(task, user)
  3.times do 
    WorkLog.make(
      :company => task.company,
      :task => task,
      :user => user, 
      :project => task.project,
      :customer => task.project.customer
    )
  end

  2.times do 
    WorkLog.make(
      :company => task.company,
      :task => task,
      :user => user,
      :project => task.project,
      :customer => task.project.customer, 
      :duration => 4.hours
    ) 
  end 
end

create_company
create_customers(3_000)
create_users(1_000)
create_admin
create_customer_users(10)
create_projects(30)
create_task(1_000)
Rake::Task["db:create_default_resource_types"].invoke(Company.first.id)
Rake::Task["db:create_default_access_levels"].invoke
