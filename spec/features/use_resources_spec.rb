require 'spec_helper'

describe 'use resources' do
  def login_as(username, password)
    visit root_path
    fill_in "Username", :with => username
    fill_in "Password", :with => password
    click_button "Login"
  end

  let(:company_use_resources) { true }
  let(:user_use_resources) { true }
  let(:company) { FactoryGirl.create(:company, :use_resources => company_use_resources) }
  let(:admin) { FactoryGirl.create(:admin, :company => company, :use_resources => user_use_resources) }

  it 'should display resources menu item if allowed' do
    login_as(admin.username, admin.password)
    page.should have_content(/resources/i)
  end

  context "when user not use resources" do
    let(:user_use_resources) { false }
    it 'should not display resources menu item if not allowed' do
      login_as(admin.username, admin.password)
      page.should_not have_content(/resources/i)
    end
  end

  context "when company not use resources" do
    let(:company_use_resources) {  false }
    it 'should not display resources menu item if not allowed' do
      login_as(admin.username, admin.password)
      page.should_not have_content(/resources/i)
    end
  end

end
