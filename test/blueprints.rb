require "machinist/active_record"
require "sham"
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

Sham.name  { Faker::Name.name }
Sham.email { Faker::Internet.email }
Sham.title { Faker::Lorem.sentence }
Sham.description  { Faker::Lorem.paragraph }
Sham.comment  { Faker::Lorem.paragraph }
Sham.password { Faker::Lorem.sentence(1) }
Sham.location { Faker::Internet.domain_name}

Company.blueprint do
  name
  subdomain { "subdomain-#{rand(1000)}-#{name}}" }
end

Customer.blueprint do
  company
  name { company.name }
end

OrganizationalUnit.blueprint do
  customer
  name
end

EmailDelivery.blueprint do
end

User.blueprint do
  company
  customer { company.internal_customer }
  name
  password
  email
  time_zone "Australia/Sydney"
  date_format { "%d/%m/%Y" }
  time_format { "%H:%M" }
  username { "user #{ name }" }
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
end

Task.blueprint do
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
end

Post.blueprint do
  user
  topic
  forum
  body { Sham.comment}
end

Forum.blueprint do
  company
  project { Project.make(:company=>company)}
  name
end

Topic.blueprint do
  forum
  title
  user
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
