# -*- encoding : utf-8 -*-
Given /^I am logged in as( a common)? (\w+)(?: with ([1-9]\d*) projects)?$/ do |common, u, project_count|
  user = FactoryGirl.create(u.to_sym)
  @current_user = user if common
  project_count.to_i.times do
    project = FactoryGirl.create :project, :company => user.company
    FactoryGirl.create :project_permission, :company => user.company, :user => user, :project => project
  end if project_count

  visit root_path
  fill_in 'user_username', :with => user.username
  fill_in 'user_password', :with => user.password
  set_subdomain(user)
  click_button 'Login'
end

Given /^I am logged in as current user$/ do 
  visit root_path
  fill_in "user_username", :with => @current_user.username
  fill_in "user_password", :with => @current_user.password
  set_subdomain(@current_user)
  sleep 5
  click_button "Login"
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
