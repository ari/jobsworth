ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

require 'test_help'
require 'lib/misc'
require File.expand_path(File.dirname(__FILE__) + "/blueprints")

require "webrat"
Webrat.configure do |config|
  config.mode = :rails
  config.open_error_files = false
end

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
                           :customer => customer)
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

  # Just set the session id to login
  def login
    @request.with_subdomain('cit')
    @user = users(:admin)
    @request.session[:user_id] = @user.id
    @user.company.create_default_statuses
  end

end

class ActionController::IntegrationTest 
  # Uses webrat to login to the system
  def login
    clear_all_fixtures

    company = Company.make
    customer = Customer.make(:company => company)
    user = User.make(:customer => customer, :company => company)

    visit "/login/login"
    fill_in "username", :with => user.username
    fill_in "password", :with => user.password
    click_button "submit"

    assert_equal user.id, @request.session[:user_id]

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
end
