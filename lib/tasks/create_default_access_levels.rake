namespace :db do
  desc 'create default resource access levels'
  task :create_default_access_levels=> :environment do
    puts "Creating default access levels"
    if AccessLevel.all.size > 0
      puts "Skipped. Access levels are already defined."
    else
      if AccessLevel.find_by_name("public")
        puts "WARNING: Access level Public already exists."
      else
        AccessLevel.create!(:name=>'public')
        puts "Access level Public created."
      end
  
      if AccessLevel.find_by_name("private")
        puts "WARNING: Access level Private already exists."
      else
        AccessLevel.create!(:name=>'private')
        puts "Access level Private created."
      end
    end
  end
end

