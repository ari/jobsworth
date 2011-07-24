Given /^system with users, projects and tasks$/ do
  company=Company.make(:subdomain=>'cit')
  2.times do
    company.users.make
    project=Project.make(:company=>company)
    2.times do
      task=Task.make(:company=>company, :project=>project)
      task.users<< company.users
    end
  end
  Task.all.each do |task|
    task.users.each do |user|
      task.work_logs.make(:user=>user)
    end
  end
end

Given /^all task names prefixed by watchers names$/ do
  Task.all.each do |task|
    task.name = task.users.collect{ |user| user.name }.join('-') + '-' + task.name
    task.save!
  end
end

Given /^I logged in as user$/ do
  @user= Company.find_by_subdomain('cit').users.first

  visit 'activities'  # 'login/login'
  fill_in "username", :with => @user.username
  fill_in "password", :with => @user.password
  click_button "submit_button"
end

Given /^I not have permission can see unwatched on all projects$/ do
  @user.project_permissions.each do |permission|
    permission.remove('see unwatched')
    permission.save!
  end
end

Given /^I have permission can see unwathced on all projects$/ do
  @user.project_permissions.each do |permission|
    permission.set('see unwatched')
    permission.save!
  end
end

Then /^I see only my tasks in widgets$/ do
  @user.widgets.each{|widget| wait_for("##{widget.dom_id}")}
  Then "I see only my tasks"
end

Then /^I see only my tasks$/ do
  (Task.all - (@user.tasks + @user.notifies)).each do |task|
    response.should_not contain(task.name)
  end
  @user.tasks.each do |task|
    response.should contain(task.name)
  end
end
Then /^I see all tasks$/ do
  wait_for(:timeout=>10) do
    @user.projects.each do |project|
      project.tasks.each do |task|
        response.should contain(task.name)
      end
    end
  end
end





