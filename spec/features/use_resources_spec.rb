require 'spec_helper'

describe 'use resources' do
  def login_as(username, password)
    visit root_path
    fill_in "Username", :with => username
    fill_in "Password", :with => password
    click_button "Login"
  end

  let(:admin) { FactoryGirl.create(:admin) }

  it 'should display resources menu item if allowed' do
    admin.update_attribute(:use_resources, true)
    admin.company.update_attribute(:use_resources, true)
    login_as(admin.username, admin.password)
    page.should have_content(/resources/i)
  end

  it 'should not display resources menu item if not allowed' do
    admin.update_attribute(:use_resources, false)
    admin.company.update_attribute(:use_resources, true)
    login_as(admin.username, admin.password)
    page.should_not have_content(/resources/i)
  end

  it 'should not display resources menu item if not allowed' do
    admin.update_attribute(:use_resources, true)
    admin.company.update_attribute(:use_resources, false)
    login_as(admin.username, admin.password)
    page.should_not have_content(/resources/i)
  end

end
