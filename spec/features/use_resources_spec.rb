require 'spec_helper'

describe 'use resources' do

  let(:company_use_resources) { true }
  let(:user_use_resources) { true }
  let(:company) { FactoryGirl.create(:company, :use_resources => company_use_resources) }
  let(:admin) { FactoryGirl.create(:admin, :company => company, :use_resources => user_use_resources) }

  before(:each) do
    signed_in_as admin
    visit root_path
  end

  it 'should display resources menu item if allowed' do
    expect(page).to have_content(/resource/i)
  end

  context "when user not use resources" do
    let(:user_use_resources) { false }

    it 'should not display resources menu item if not allowed' do
      expect(page).not_to have_content(/resource/i)
    end
  end

  context "when company not use resources" do
    let(:company_use_resources) {  false }

    it 'should not display resources menu item if not allowed' do
      expect(page).not_to have_content(/resource/i)
    end
  end

end
