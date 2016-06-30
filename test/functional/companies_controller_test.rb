require 'test_helper'

class CompaniesControllerTest < ActionController::TestCase
  context 'admin' do
    setup do
      @user = User.make(:admin)
      sign_in @user
      @request.session[:user_id] = @user.id
      @user.company.create_default_statuses
    end

    should '/edit should render :success' do
      get :edit, :id => @user.company.id
      assert_response :success
    end
  end

  context 'common user' do
    setup do
      @request.with_subdomain('cit')
      @user = User.make
      sign_in @user
      @request.session[:user_id] = @user.id
      @user.company.create_default_statuses
    end

    should 'visit show_logo render :success' do
      get :show_logo , :id => @user.company.id
      assert_response :success
    end
  end

end
