require "machinist/active_record"
require "sham"
require 'faker'

module Faker
  class Lorem
    def self.sentences(sentence_count = 3)
      (0..sentence_count).map { sentence }
    end

    def self.paragraphs(paragraph_count = 3)
      (0..paragraph_count).map { paragraph }
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
  subdomain { "subdomain-#{Time.now.to_i}-#{rand(36**8).to_s(36)}" }
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
  customer { Customer.make(:company => company) }
  name
  password
  email { Sham.email.gsub("@", "-#{rand(36**8).to_s(36)}@") }
  time_zone "Australia/Sydney"
  date_format   { "%d/%m/%Y" }
  time_format   { "%H:%M" }
  username      { "user #{ name }" }
  option_tracktime 1
  receive_notifications 1
  receive_own_notifications true
end

User.blueprint(:admin) do
  admin 10
end

Project.blueprint do
  name
  customer
  company
  default_estimate 1.0
end

Project.blueprint(:completed) do
  completed_at { Time.now }
end

ProjectPermission.blueprint do
  can_comment       true
  can_work          true
  can_report        true
  can_create        true
  can_edit          true
  can_reassign      true
  can_close         true
  can_grant         true
  can_milestone     true
  can_see_unwatched true
end

AbstractTask.blueprint do
  name
  description {Faker::Lorem.paragraph }
  company
  project
  weight_adjustment { 0 }
end

TaskRecord.blueprint do
  customers { [Customer.make] }
end

Template.blueprint do
end

Milestone.blueprint do
  name
  company
  project
  status_name { :open }
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
  body { Sham.comment }
  customer { Customer.make(:company=>company)}
  user { User.make(:company=>company, :projects=>[project])}
  project { Project.make(:customer=>customer,:company=>company)}
  started_at { Time.now }
  task { TaskRecord.make(:project=>project, :company=>company, :users=> [user])}
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

ProjectFile.blueprint do
  company
  project  { Project.make(:company=>company)}
  customer #{ Customer.make(:company=>company)}
  task     { TaskRecord.make(:project=>project)}
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

Snippet.blueprint do
  name { Sham.name }
  body { Sham.comment }
end

Service.blueprint do
  name { Sham.name }
  description { Sham.comment }
end

ServiceLevelAgreement.blueprint do
  billable false
end

WorkPlan.blueprint do
end

Property.blueprint do
  name
end

PropertyValue.blueprint do
  value  { Faker::Name.name }
  default true
  position 1
end
