# -*- encoding : utf-8 -*-
Given /^I am logged in as (\w+)(?: with ([1-9]\d*) projects)$/ do |u, project_count|
  user = FactoryGirl.create(u.to_sym)
  project_count.to_i.times do
    project = FactoryGirl.create :project, :company => user.company
    FactoryGirl.create :project_permission, :company => user.company, :user => user, :project => project
  end if project_count

  visit root_path
  fill_in 'user_username', :with => user.username
  fill_in 'user_password', :with => user.password
  find('#user_subdomain').set(user.company.subdomain)
  click_button 'Login'
end