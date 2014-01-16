#Export the environment variable DB_USERNAME, DB_HOST, DB_PASSWORD before running the script
#!/bin/bash -e

echo "test:
 adapter: <%= RUBY_ENGINE=='jruby' ? 'jdbcmysql' : 'mysql2' %>
 database: jobsworth_dev
 host: ${DB_HOST}
 username: ${DB_USERNAME}
 password: ${DB_PASSWORD}
 encoding: utf8" > $WORKSPACE/config/database.yml

#!/bin/bash
# Delete previous files
rm -f ${WORKSPACE}/ROOT.war
rm -rf ${WORKSPACE}/tmp/


echo "### Copying application.yml for jruby ###"
cp ${WORKSPACE}/config/application.example.tomcat.yml ${WORKSPACE}/config/application.yml

source "$HOME/.rvm/scripts/rvm"
rvm get stable
rvm install `cat .ruby-version`
rvm use --create `cat .ruby-version`@`cat .ruby-gemset`


echo "### Updating bundler ###"
gem update bundler

echo "### Installing gems ###"
bundle install

export RAILS_ENV=test
export CI=true
export COVERAGE=true
export JRUBY_OPTS=--1.9

echo "### Starting to load the database schema ###"
jruby -S bundle exec rake db:drop db:create db:schema:load

export JRUBY_OPTS="-J-Xmx3072m -J-XX:MaxPermSize=512m"

echo "### Starting minitest tests ###"
jruby  -J-server -S bundle exec rake ci:setup:minitest test RCOV_PARAMS="--aggregate coverage/aggregate.data"

echo "### Starting RSpec tests ###"
jruby -J-server -S bundle exec rake ci:setup:rspec spec RCOV_PARAMS="--aggregate coverage/aggregate.data" 

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

echo "### Building war file ###"
bundle exec warble war:clean
bundle exec warble war

echo "### Renaming file to ROOT.war ###"
mv *.war ROOT.war
exit 0
