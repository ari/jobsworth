require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  fixtures(:users)
  
  context "a logged in admin user" do
    setup do
      login
    end
    
    should "should render edit" do
      other = User.make(:company => @user.company)
      get :edit, :id => other.id
      assert_response :success
    end

    should "redirect /update to /clients/edit" do
      customer = @user.company.customers.first
      post(:update, :id => @user.id, :user => { :name => "test", 
             :customer_id => customer.id })

      assert_redirected_to(:id => customer.id, :anchor => "users",
                           :controller => "clients", :action => "edit")
    end
  end

  context "a logged in non-admin user" do
    setup do
      login
      @user.update_attribute(:admin, false)
    end

    should "restrict edit page to admin user" do
      other = User.make(:company => @user.company)
      get :edit, :id => other.id
      assert_redirected_to "/users/edit_preferences"
      assert_equal "Only admins can edit users.", flash["notice"]
    end
  end

end
