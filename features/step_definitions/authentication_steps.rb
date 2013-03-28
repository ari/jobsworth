# -*- encoding : utf-8 -*-
Given /^I am logged in as (\w+)(?: with ([1-9]\d*) projects)$/ do |u, project_count|
  user = FactoryGirl.create(u.to_sym)
  FactoryGirl.create_list(:project_permission, project_count.to_i, :company => user.company, :user => user ) if project_count

  visit root_path
  fill_in 'user_username', :with => user.username
  fill_in 'user_password', :with => user.password
  find('#user_subdomain').set(user.company.subdomain)
  click_button 'Login'
end