Given /^I logged in as "([^\"]*)"$/ do |user|
  current_user=User.find_by_name(user)
end

When /^I click on "([^\"]*)"  link$/ do |link|
  click_link link
end

Then /^I receive  "([^\"]*)" page for "([^\"]*)"$/ do |page, project|
  response.should be_success
  current_link.should == path_to(page, Project.find_by_name(project))
end

When /^I select "([^\"]*)" from "([^\"]*)" list$/ do |value, list|
  select value, :from => list
end


When /^I click "([^\"]*)" button$/ do |button|
  click_button button
end

Then /^I receive "([^\"]*)" page$/ do |arg1|
  response.should be_success
  current_link.should == path_to(page)
end

Then /^I see "([^\"]*)" project with "([^\"]*)" background$/ do |name, color|
  response.should have_selector('a', :title=>name, :class=>color)
end

Given /^the following projects$/ do |table|
  # table is a Cucumber::Ast::Table
  pending # express the regexp above with the code you wish you had
end

Given /^the following access levels$/ do |table|
  # table is a Cucumber::Ast::Table
  pending # express the regexp above with the code you wish you had
end

