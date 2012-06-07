require "machinist/active_record"
require "sham"
require 'faker'

# 'task' used below in machinist conflicts with Rake keyword 'task'
# Following line removes 'task' definition from Rake to fix the conflict
Rake::DeprecatedObjectDSL.send :remove_method, :task if defined? Rake

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

Sham.name  { Faker::Name.name }
Sham.email { Faker::Internet.email }
Sham.title { Faker::Lorem.sentence }
Sham.description  { Faker::Lorem.paragraph }
Sham.comment  { Faker::Lorem.paragraph }
Sham.password { Faker::Lorem.sentence(1) }
Sham.location { Faker::Internet.domain_name}

Company.blueprint do
  name
  subdomain { "subdomain-#{Time.now.to_i + rand(10000)}-#{name}}" }
end

Customer.blueprint do
  company
  name { Faker::Name.name }
end

OrganizationalUnit.blueprint do
  customer
  name
end

EmailDelivery.blueprint do
  work_log
  user
  email { Sham.email }
end

EmailAddress.blueprint do
  email { Sham.email.gsub("@", "-#{rand(36**8).to_s(36)}@") }
end

User.blueprint do
  company
  customer { company.internal_customer }
  name
  password
  email { Sham.email.gsub("@", "-#{rand(36**8).to_s(36)}@") }
  time_zone "Australia/Sydney"
  date_format   { "%d/%m/%Y" }
  time_format   { "%H:%M" }
  username      { "user #{ name }" }
  working_hours { "8.0|8.0|8.0|8.0|8.0|0.0|0.0" }
end

Project.blueprint do
  name
  customer
  company
end

AbstractTask.blueprint do
  name
  description {Faker::Lorem.paragraph }
  company
  project
  weight { 100 }
  weight_adjustment { 100 }
end

Task.blueprint do
  customers { [Customer.make] }
end

Milestone.blueprint do
  name
  company
  project
end

ResourceType.blueprint do
  name
  company
end

Resource.blueprint do
  name
  company
  customer
  resource_type
end

TaskFilter.blueprint do
  name
  user
  company { user.company }
end

TaskFilterUser.blueprint do
end

TaskPropertyValue.blueprint do
end

Tag.blueprint do
  company
  name
end

WorkLog.blueprint do
  company
  customer { Customer.make(:company=>company)}
  body { Sham.comment }
  project { Project.make(:customer=>customer,:company=>company)}
  user { User.make(:company=>company, :projects=>[project])}
  task { Task.make(:project=>project, :company=>company, :users=> [user])}
  started_at { Time.now }
  event_log { EventLog.make(:company => company, :project => project, :user => user) }
end

Sheet.blueprint do
  task
  project
  user
end

TimeRange.blueprint do
  name
end

Trigger.blueprint do
  company
  event_id { 1 }
end

Page.blueprint do
  name
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
  name
  company
end

ScmProject.blueprint do
  company
  scm_type { ['git', 'svn', 'cvs', 'mercurial', 'bazar'][rand(4)]}
  location
end

ScmChangeset.blueprint do
  scm_project
  message { Sham.comment }
  author  { Sham.name }
  commit_date { Time.now - 3.days }
  changeset_num { rand(1000000) }
  task
end

Widget.blueprint do
  order_by { "priority" }
  mine { true }
  collapsed { false }
end

ScoreRule.blueprint do
  name       { Faker::Name.name }
  score      { 100 }
  exponent   { 1.2 }  
  score_type { ScoreRuleTypes::FIXED }
end

NewsItem.blueprint do
  body { Faker::Name.name }
  portal { true }
end

EventLog.blueprint do
  company
  project
  user
  event_type { rand(8) }
end
