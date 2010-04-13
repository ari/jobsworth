Given /^I logged in as user$/ do
  #Fixtures.reset_cache
  #fixtures_folder = File.join(RAILS_ROOT, 'test', 'fixtures')
  #fixtures = Dir[File.join(fixtures_folder, '*.yml')].map {|f| File.basename(f, '.yml') }
  #Fixtures.create_fixtures(fixtures_folder, fixtures)

  @user= Company.find_by_subdomain('cit').users.first
  visit 'activities/list'  # 'login/login'

  fill_in "username", :with => @user.username
  fill_in "password", :with => @user.password
  click_button "submit_button"
end

Given /^I have permission can only see watched on all projects$/ do
  @user.project_permissions.each do |p|
    p.can_only_see_watched=true
    p.save!
  end
end


