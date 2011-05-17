require 'spec_helper'
include Devise::TestHelpers

describe ScoreRuleController do

  describe "GET 'index'" do

    context 'When the user is not logged in' do
      it 'should redirect to the login page' do
        get :index
        response.should redirect_to 'users/signin'
      end
    end

    context 'When the user is logged in' do
      it 'should display a list of score rules assigned to the project'
      
    end
  end
end
