require 'faker' if Rails.env.staging?

def dont_run
  puts "This task should be runned only in staging, but you're in #{Rails.env} environment."
  puts "Exiting task without changes to database."
  exit
end

def drop_db
  puts "Droping tables"
  Rake::Task['db:reset'].invoke
end

def populate_db
  Rake::Task['db:setup'].invoke
  puts "Done."
end

namespace :db do
  desc 'Fill database with example data'
  task :populate => :environment do
    dont_run unless Rails.env.staging?
    drop_db
    populate_db
  end
end
