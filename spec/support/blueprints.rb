require 'machinist/active_record'
require 'faker'

module Faker
  class Lorem
     def self.sentences(sentence_count = 3)
      sentences = []
      1.upto(sentence_count) do
        sentences << sentence
      end
      sentences
    end

    def self.paragraphs(paragraph_count = 3)
      paragraphs = []
      1.upto(paragraph_count) do
        paragraphs << paragraph
      end
      paragraphs
    end
  end
end

random_name = Faker::Name.name
random_email = Faker::Internet.email
random_title = Faker::Lorem.sentence
random_description = Faker::Lorem.paragraph
random_comment = Faker::Lorem.paragraph
random_password= Faker::Lorem.sentence(1)
random_location= Faker::Internet.domain_name

Company.blueprint do
  name      { random_name }
  subdomain { "subdomain-#{rand(1000)}-#{name}}" }
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
  company  { Company.make }
  customer { Customer.make }
  name { random_name }
  password { random_password }
  email { random_email }
  #time_zone "Australia/Sydney"
  date_format { "%d/%m/%Y" }
  time_format { "%H:%M" }
  username { "user" }
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
  company
  customer { Customer.make(:company=>company)}
  body { Faker::Lorem.paragraph }
  project { Project.make(:customer=>customer,:company=>company)}
  user { User.make(:company=>company, :projects=>[project])}
  task { Task.make(:project=>project, :company=>company, :users=> [user])}
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
  company
  project  { Project.make(:company=>company)}
  customer #{ Customer.make(:company=>company)}
  task     { Task.make(:project=>project)}
  user     { User.make(:company=>company, :customer=>customer)}
  file_file_size 1000
  uri      1020303303
end

WikiPage.blueprint do
  name{ "some project name" }
  company
end

ScmProject.blueprint do
  company
  scm_type { ['git', 'svn', 'cvs', 'mercurial', 'bazar'][rand(4)]}
  location { Faker::Internet.domain_name }
end

ScmChangeset.blueprint do
  scm_project
  message { Faker::Lorem.paragraph }
  author  { Faker::Name.name }
  commit_date { Time.now - 3.days }
  changeset_num { rand(1000000) }
  task
end

Widget.blueprint do
  order_by { "priority" }
  mine { true }
  collapsed { false }
end
