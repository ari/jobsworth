#!/bin/sh

# Update to the latest code from git

echo "Upgrading gem system"
gem update --system

echo "Update from git"
git checkout db/schema.rb
git pull

echo "Verify and install any new gems required."
bundle install --deployment --without development test

echo "Run database migrations if required."
bundle exec rake db:migrate RAILS_ENV=production

echo "Clear cached files."
bundle exec rake tmp:cache:clear

echo "Rebuild the CSS"
bundle exec rake assets:precompile

echo "Restart passenger."
touch tmp/restart.txt

echo "Restart the background processor."
bundle exec lib/daemons/scheduler.rb restart