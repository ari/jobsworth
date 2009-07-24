require "machinist/active_record"
require "sham"
require 'faker'

Sham.name  { Faker::Name.name }
Sham.email { Faker::Internet.email }
Sham.title { Faker::Lorem.sentence }
Sham.description  { Faker::Lorem.paragraph }
Sham.comment  { Faker::Lorem.paragraph }
Sham.password { Faker::Lorem.sentence(1) }

Company.blueprint do
  name
  subdomain { "subdomain #{ name }" }
end

Customer.blueprint do
  company
  name { company.name }
end

User.blueprint do
  company
  customer
  name
  password 
  time_zone "Australia/Sydney"
  username { "user #{ name }" }
end

Project.blueprint do
  name
  customer
end

Task.blueprint do
  name
  company
end
