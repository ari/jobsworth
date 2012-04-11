namespace :db do
  desc 'create default resource access levels'
  task :create_default_access_levels=> :environment do
    puts "create public access level."
    AccessLevel.create!(:name=>'public')

    puts "create private access level."
    AccessLevel.create!(:name=>'private')
  end
end

