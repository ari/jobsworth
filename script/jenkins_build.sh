#!/bin/bash

export PATH=~/.rbenv/shims

echo "### Set up Ruby ###"
rbenv init
rbenv install
gem install bundler

echo "### Installing gems ###"
gem update bundler
bundle install

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
export COVERAGE=true
export JRUBY_OPTS=--1.9

echo "### Starting to load the database schema ###"
bundle exec rake db:drop db:create db:schema:load

export JRUBY_OPTS="-J-Xmx3072m -J-XX:MaxPermSize=512m"

echo "### Starting minitest tests ###"
bundle exec rake ci:setup:testunit test RCOV_PARAMS="--aggregate coverage/aggregate.data"

echo "### Starting RSpec tests ###"
bundle exec rake ci:setup:rspec spec RCOV_PARAMS="--aggregate coverage/aggregate.data" 

echo "### Installing warbler ###"
gem install warbler

export RAILS_ENV=production

echo "### Clearing cached files ###"
bundle exec rake tmp:cache:clear 

echo "Clearing public/assets"
rm -rf ${WORKSPACE}/public/assets/*

echo "### Rebuilding CSS ###"
bundle exec rake assets:precompile 

echo "### Copying database.jruby.yml to database.yml ###"
cp $WORKSPACE/config/database.jruby.yml $WORKSPACE/config/database.yml

echo ${BUILD_NUMBER} > $WORKSPACE/config/jenkins.build

export JOBSWORTH_DISABLE_SCHEDULER=true

echo "### Clearing out files not needed in production ###"
rm -rf ${WORKSPACE}/tmp/*
rm -rf ${WORKSPACE}/public/cucumber_test_assets
rm -rf ${WORKSPACE}/vendor/assets/*
rm -rf ${WORKSPACE}/app/assets/*
# rm -rf ${WORKSPACE}/log/*

echo "### Rerunning Bundler to exclude gems that are not needed ###"
# .bundle/config should exclude gem groups that are also excluded in config/warble.rb for rails-console to work.
bundle install --without assets development test cucumber
#ln -s ../gems ${WORKSPACE}/vendor/bundle

echo "### Building war file ###"
bundle exec warble war:clean
bundle exec warble war

echo "### Renaming file to ROOT.war ###"
mv *.war ROOT.war

exit 0
