require 'rubygems'
require 'spork'
require 'simplecov'

Spork.prefork do
  ENV["RAILS_ENV"] ||= 'test'
    
  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'

  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

  RSpec.configure do |config|
    config.mock_with :rspec
    config.fixture_path = "#{::Rails.root}/test/fixtures"

    config.include Devise::TestHelpers, :type => :controller

    config.use_transactional_fixtures = true
    config.use_instantiated_fixtures  = false
    ActiveSupport::Dependencies.clear
    require File.join(RAILS_ROOT,'test','blueprints')

#    config.before(:each) do
#      load File.expand_path(File.dirname(__FILE__) + "/t/blueprints.rb") 
#    end

    DatabaseCleaner.strategy = :truncation
  end 
end

Spork.each_run do
  SimpleCov.start 'rails'
  DatabaseCleaner.clean
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

  visit "/login/login"
  fill_in "username", :with => user.username
  fill_in "password", :with => user.password
  click_button "submit_button"

  return user
end
