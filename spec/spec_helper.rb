# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'

require 'simplecov'
SimpleCov.start 'rails'
  
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require File.join(RAILS_ROOT,'test','blueprints')

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec
  config.include Devise::TestHelpers, :type => :controller
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/test/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
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
