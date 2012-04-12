namespace :db do
  desc 'create default resource access levels'
  task :create_default_access_levels=> :environment do
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

