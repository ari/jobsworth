Given /^I am on a project edit page$/ do
  visit edit_project_path Project.first
end

Given /^I am on a project show page$/ do
  visit project_path Project.first
end