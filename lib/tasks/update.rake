namespace :update do

  desc "Update to the latest code"
  task :git do

    puts "Update from git."
    system "git checkout db/schema.rb"
    system "git pull"

    puts "Verify and install any new gems required."
    system "bundle install --deployment --without development test"

    puts "Run database migrations if required."
    system "bundle exec rake db:migrate RAILS_ENV=production"

    puts "Clear cached files."
    system "bundle exec rake tmp:cache:clear"

    system "rm -f public/javascripts/main.js"
    system "rm -f public/javascripts/prototype-all.js"
    system "rm -f public/stylesheets/all.css"

    puts "Restart Apache httpd."
    system "apachectl graceful"
    system "script/delayed_job restart"
  end

  task :default => "update:git"
end
