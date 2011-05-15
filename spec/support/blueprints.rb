require 'machinist/active_record'
require 'faker'

random_name = Faker::Name.name
random_email = Faker::Internet.email
random_title = Faker::Lorem.sentence
random_description = Faker::Lorem.paragraph
random_comment = Faker::Lorem.paragraph
random_password= Faker::Lorem.sentence(1)
random_location= Faker::Internet.domain_name

Company.blueprint do
  name      { random_name }
  subdomain { Faker::Internet.domain_name }
end

Customer.blueprint do
  company { Company.make }
  name    { random_name }
end

OrganizationalUnit.blueprint do
  customer { Customer.make }
  name { random_name }
end

EmailDelivery.blueprint do
end

User.blueprint do
  company  { Company.make! }
  customer { Customer.make! }
  name { random_name }
  password { random_password }
  email { random_email }
  #time_zone "Australia/Sydney"
  date_format { "%d/%m/%Y" }
  time_format { "%H:%M" }
  username { "user_#{serial_number}" }
end

Project.blueprint do
  name { random_name }
  customer { Customer.make }
  company { Company.make }
end

AbstractTask.blueprint do
  name { random_name }
  description { random_description }
  company { Company.make }
  project { Project.make }
end

Task.blueprint do
  company { Company.make }
  project { Project.make }
  users   { [User.make] }
  weight  { 1 }
end

Milestone.blueprint do
  name { random_name }
  company { Company.make }
  project { Project.make }
end

ResourceType.blueprint do
  name { random_name }
  company { Company.make }
end

Resource.blueprint do
  name { random_name }
  company { Company.make }
  customer { Customer.make }
  resource_type { ResourceType.make }
end

TaskFilter.blueprint do
  name { "some project name" }
  user { User.make }
  company { user.company }
end

TaskFilterUser.blueprint do
end

TaskPropertyValue.blueprint do
end

Tag.blueprint do
  company { Company.make }
  name { random_name }
end

WorkLog.blueprint do
  prebuild_co      = Company.make!
  prebuild_cus     = Customer.make!(:company => prebuild_co)
  prebuild_project = Project.make!(:customer => prebuild_cus, :company => prebuild_co)
  prebuild_user    = User.make!(:company => prebuild_co, :projects => [prebuild_project])

  company  { prebuild_co }
  customer { prebuild_cus }
  body     { Faker::Lorem.paragraph }
  project  { prebuild_project }
  user     { prebuild_user }
  task     { Task.make(:project => prebuild_project, 
             :company => prebuild_co, :users=> [prebuild_user]) }
  started_at { Time.now }
end

Sheet.blueprint do
  task
  project
  user
end

TimeRange.blueprint do
  name{ "some project name" }
end

Trigger.blueprint do
  company
  event_id { 1 }
end

Page.blueprint do
  name{ "some project name" }
  company
  notable { Project.make(:company=>company) }
end

ProjectFile.blueprint do
  prebuild_co  = Company.make!
  prebuild_pro = Project.make!(:company  => prebuild_co)
  prebuild_cus = Customer.make!(:projects => [prebuild_pro])

  company  { prebuild_co }
  project  { prebuild_pro }
  customer { prebuild_cus }
  task     { Task.make!(:project => prebuild_pro) }
  user     { User.make!(:company => prebuild_co, :customer => prebuild_cus) }
  file_file_size { 999 }
  uri      { "http://example.com" }
end

WikiPage.blueprint do
  name { "some project name" }
  company
end

ScmProject.blueprint do
  company { Company.make! }
  scm_type { ['git', 'svn', 'cvs', 'mercurial', 'bazar'][rand(4)]}
  location { Faker::Internet.domain_name }
end

ScmChangeset.blueprint do
  scm_project { ScmProject.make! }
  message     { Faker::Lorem.paragraph }
  author      { Faker::Name.name }
  commit_date { Time.now - 3.days }
  changeset_num { rand(1000000) }
  task { Task.make! }
end

Widget.blueprint do
  order_by { "priority" }
  mine { true }
  collapsed { false }
end
