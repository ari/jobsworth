require 'rubygems'
require 'spork'
require 'simplecov'
require 'test/unit'

Spork.prefork do
  unless ENV['DRB']
    require 'simplecov'
    SimpleCov.start 'rails'
  end
  
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  # require 'spork/ext/ruby-debug'
  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

  RSpec.configure do |config|
    config.mock_with :rspec
    config.fixture_path = "#{::Rails.root}/test/fixtures"
    config.use_transactional_fixtures = true

    config.include Devise::TestHelpers, :type => :controller

    config.before(:all)    { Sham.reset(:before_all)  }
    config.before(:each)   { Sham.reset(:before_each) }
  end 

  DatabaseCleaner.strategy = :truncation
  ActiveSupport::Dependencies.clear
end

Spork.each_run do
  require Rails.root.join('test','blueprints')
  if ENV['DRB']
      require 'simplecov'
      SimpleCov.start 'rails'
  end
  DatabaseCleaner.clean
end

def sign_in_admin(user_params = {})
  user_params.merge!(:admin => 1)
  @logged_user = User.make(user_params)
  sign_in @logged_user
end

def sign_in_normal_user(user_params = {})
  @logged_user = User.make(user_params)
  sign_in @logged_user
end

def login_user(params={ })
  user=mock_model(User, params.merge(:locale=>nil, 'seen_welcome?' => true, :time_zone=> "Europe/Kiev") )
  session[:user_id]=user.id
  session[:remember_until] = Time.now + 1.week
  controller.stub!(:current_user).and_return(user)
end

def login_using_browser
  Company.destroy_all
  company = Company.make
  customer = Customer.make(:company => company)
  user = User.make(:customer => customer, :company => company)

  visit "/users/sign_in"
  fill_in "username", :with => user.username
  fill_in "password", :with => user.password
  click_button "submit_button"

  return user
end
