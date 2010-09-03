namespace :update do

  desc "Update to the latest code"
  task :git do

    puts "Update from git."
    system "git checkout db/schema.rb"
    system "git pull"

    puts "Verify and install any new gems required."
    Rake::Task['gems:install'].invoke

    puts "Run database migrations if required."
    system "rake db:migrate RAILS_ENV=production"

    puts "Clear cached files."
    Rake::Task['tmp:cache:clear'].invoke

    system "rm -f public/javascripts/main.js"
    system "rm -f public/javascripts/prototype-all.js"
    system "rm -f public/stylesheets/all.css"

    puts "Restart Apache httpd."
    system "apachectl graceful"
  end

  task :default => "update:git"
end