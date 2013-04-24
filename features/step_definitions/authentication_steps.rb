# -*- encoding : utf-8 -*-
include Warden::Test::Helpers

After { Warden.test_reset! }

Given /^I am logged in as( a common)? (\w+)(?: with ([1-9]\d*) projects)?( via login form)?$/ do |common, user_type, project_count, form|
  user = create_user user_type
  create_projects_for user, project_count

  @current_user = user if common

  unless form
    login_as user
    visit root_path
  else
    visit root_path
    fill_login_form user
  end
end

Given /^I am logged in as current user( via login form)?$/ do |form|
  unless form
    login_as @current_user
    visit root_path
  else
    visit root_path
    fill_login_form @current_user
  end
end



def create_user(factory_method)
  FactoryGirl.create factory_method.to_sym
end

def create_projects_for(user, project_count)
  project_count.to_i.times do
    project = FactoryGirl.create :project, :company => user.company
    FactoryGirl.create :project_permission, :company => user.company, :user => user, :project => project
  end if project_count
end

def set_subdomain(user)
  case Capybara.current_driver
  when :rack_test
    find('#user_subdomain').set(user.company.subdomain)
  when :selenium
    page.execute_script("document.getElementById('user_subdomain').value = '#{user.company.subdomain}'")
  when :poltergeist
    page.execute_script("setTimeout( function(){ document.getElementById('user_subdomain').value = '#{user.company.subdomain}'}, 2000 )")
  end
end

def fill_login_form(user)
  fill_in 'user_username', with: user.username
  fill_in 'user_password', with: user.password
  set_subdomain user
  click_button 'Login'
end
