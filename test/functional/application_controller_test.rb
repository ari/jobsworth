require 'test_helper'

class ApplicationControllerTest < ActionController::TestCase
  tests ActivitiesController

  fixtures :customers

  signed_in_admin_context do

    should 'get current_user' do
       get :index
    end

    should 'user 1 be an admin' do
       get :index
       assert assigns(:current_user).admin?
    end

    should 'user 2 NOT to be an admin' do
      user = User.make
      user.company.create_default_statuses
      sign_in user
      @request.session[:user_id] = user.id
      get :index
      assert !assigns(:current_user).admin?
    end

    should 'clients menu item to be showed for non admin users with read client option' do
      user = User.make(:read_clients => true)
      get :index
      assert_response :success
    end

    should 'clients menu item to be not showed for non admin users without read client option' do
      user = User.make(:read_clients => false)
      get :index
      assert_response :success
    end

    should 'never redirect back to url with ?format=js' do
      session[:history] = ['/tasks?format=js']
      get :redirect_from_last
      assert_redirected_to root_url
    end

  end

end
