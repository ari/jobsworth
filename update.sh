#!/bin/sh

# Use this script to update jobsworth to the current version on whichever
# git branch you are already on

# It is designed to work with a passenger deployment, but it might work well
# for other deployment choices as well.

# This script should be run as root.

APP_USER=`ls -l config/environment.rb | awk '{print $3}'`

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
bundle exec rake tmp:cache:clear RAILS_ENV=production

echo "Rebuild the CSS"
bundle exec rake assets:precompile RAILS_ENV=production
chown -R $APP_USER tmp public

echo "Restart passenger."
touch tmp/restart.txt

echo "Restart the background processor."
bundle exec lib/daemons/scheduler.rb restart
