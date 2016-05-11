#!/bin/bash

echo "### Installing gems ###"
bundle install --with assets development test cucumber --without mri

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
export JENKINS=true

echo "### Starting to load the database schema ###"
bundle exec rake db:drop db:create db:schema:load

echo "### Starting minitest tests ###"
bundle exec rake test

echo "### Starting RSpec tests ###"
bundle exec rake rspec spec

export RAILS_ENV=production
export COMPILING_ASSETS=true

echo "### Copying database.jruby.yml to database.yml ###"
cp $WORKSPACE/config/database.jruby.yml $WORKSPACE/config/database.yml

echo "Clearing public/assets and rebuilding CSS"
bundle exec rake tmp:cache:clear 
rm -rf ${WORKSPACE}/public/assets/*
bundle exec rake assets:precompile

echo ${BUILD_NUMBER} > $WORKSPACE/config/jenkins.build

echo "### Rerunning Bundler to exclude gems that are not needed ###"
# .bundle/config should exclude gem groups that are also excluded in config/warble.rb for rails-console to work.
bundle install --without assets development test cucumber mri

echo "### Building war file ###"
bundle exec warble war:clean war

exit 0
