#!/bin/bash

export PATH=~/.rbenv/shims
export JRUBY_OPTS="-J-Xmx3072m -J-XX:MaxPermSize=512m"

echo "### Set up Ruby ###"
rbenv init
rbenv install
gem install bundler

echo "### Installing gems ###"
gem update bundler
bundle install
gem install warbler

#Export the environment variable DB_USERNAME, DB_HOST, DB_PASSWORD before running the script

echo "test:
 adapter: <%= RUBY_ENGINE=='jruby' ? 'jdbcmysql' : 'mysql2' %>
 database: jobsworth_dev
 host: ${DB_HOST}
 username: ${DB_USERNAME}
 password: ${DB_PASSWORD}
 encoding: utf8" > $WORKSPACE/config/database.yml

echo "### Copying application.yml for jruby ###"
cp ${WORKSPACE}/config/application.example.tomcat.yml ${WORKSPACE}/config/application.yml

export RAILS_ENV=test
export CI=true

echo "### Starting to load the database schema ###"
bundle exec rake db:drop db:create db:schema:load

echo "### Starting minitest tests ###"
bundle exec rake ci:setup:testunit test RCOV_PARAMS="--aggregate coverage/aggregate.data"

echo "### Starting RSpec tests ###"
bundle exec rake ci:setup:rspec spec RCOV_PARAMS="--aggregate coverage/aggregate.data" 



export RAILS_ENV=production

echo "Clearing public/assets and rebuilding CSS"
bundle exec rake tmp:cache:clear 
rm -rf ${WORKSPACE}/public/assets/*
bundle exec rake assets:precompile

echo "### Copying database.jruby.yml to database.yml ###"
cp $WORKSPACE/config/database.jruby.yml $WORKSPACE/config/database.yml

echo ${BUILD_NUMBER} > $WORKSPACE/config/jenkins.build

export JOBSWORTH_DISABLE_SCHEDULER=true

echo "### Rerunning Bundler to exclude gems that are not needed ###"
# .bundle/config should exclude gem groups that are also excluded in config/warble.rb for rails-console to work.
bundle install --without development test cucumber

echo "### Building war file ###"
bundle exec warble war:clean
bundle exec warble war

exit 0
