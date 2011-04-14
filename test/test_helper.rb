require 'simplecov'
SimpleCov.start 'rails'

ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
  
require 'rails/test_help'
require "#{Rails.root}/lib/misc"
require "#{Rails.root}/test/blueprints"
require "capybara/rails"
require 'shoulda_macros/auth'

include ActionMailer::TestHelper

class ActiveSupport::TestCase
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
  fixtures :all

  setup { Sham.reset }

  # Returns a project with a few tasks.
  # Milestones will also be created if options[:make_milestones] is true
  # The project will belong to user's company and user will have full
  # access to the project.
  # The user will also be on the assigned list for the tasks.
  def project_with_some_tasks(user, options = {})
    task_count = options[:task_count] || 2
    customer = options[:customer] || user.company.internal_customer
    make_milestones = options[:make_milestones]

    project = Project.make(:company => user.company,
                           :customer => customer, :owner=>user)
    perm = project.project_permissions.build(:user => user)
    perm.set("all")
    project.save!

    if make_milestones
      2.times { project.milestones.make }
    end

    task_count.times do
      t = Task.make_unsaved(:project => project, :company => project.company)
      t.users << user
      t.milestone = project.milestones.rand
      t.save!
    end

    return project
  end
end

module ActionController
  class TestRequest
    def with_subdomain(subdomain=nil)
      the_host_name = "www.localhost.com"
      the_host_name = "#{subdomain}.localhost.com" if subdomain
      self.host = the_host_name
      self.env['SERVER_NAME'] = the_host_name
      self.env['HTTP_HOST'] = the_host_name
    end

    def server_name
      self.env['SERVER_NAME']
    end
  end
end

class ActionController::TestCase
  include Devise::TestHelpers
  # Just set the session id to login
end

class ActionController::IntegrationTest
  include Capybara
  def login
    clear_all_fixtures
    company = Company.make
    customer = Customer.make(:company => company)
    user = User.make(:customer => customer, :company => company)

    visit "/users/sign_in"
    fill_in "user_username", :with => user.username
    fill_in "user_password", :with => user.password
    click_button "user_submit"

    return user
  end

  # Need to make sure fixtures don't interfere with our blueprints
  def clear_all_fixtures
    Company.destroy_all
  end

  # Uses webrat to logout of the system
  def logout
    visit "/login/logout"
  end
  teardown do
    Capybara.reset_sessions!
  end
end
