#!/bin/sh

# Use this script to update jobsworth to the current version on whichever
# git branch you are already on

# It is designed to work with a passenger deployment, but it might work well
# for other deployment choices as well.

# This script should be run as root.

APP_USER=`ls -l config/environment.rb | awk '{print $3}'`
EXEC="RAILS_ENV=production bundle exec"

# Update to the latest code from git

echo "Upgrading gem system"
gem update --system

echo "Update from git"
git checkout db/schema.rb
git pull

echo "Verify and install any new gems required."
bundle install --deployment --without development test

echo "Rebuild the CSS in separate thread"
$EXEC rake assets:precompile &

echo "Run database migrations if required."
$EXEC rake db:migrate

echo "Clear cached files."
chown -R $APP_USER tmp public
$EXEC rake tmp:cache:clear

echo "Restart passenger."
touch tmp/restart.txt

echo "Restart the background processor."
$EXEC script/scheduler.rb restart

echo "restart delayed job worker."
$EXEC script/delayed_job restart