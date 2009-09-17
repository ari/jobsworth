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

    context "creating a user" do
      setup do
        customer = @user.company.customers.first
        new_user = User.make_unsaved(:customer_id => customer.id, :company => @user.company)
        @user_params = new_user.attributes

        ActionMailer::Base.deliveries.clear
      end

      should "be able to create a user" do
        post(:create, :user => @user_params)
        created = assigns(:user)
        assert !created.new_record?
        assert_redirected_to :action => "edit", :id => created.id
      end
      
      should "send a welcome email if :send_welcome_mail is checked" do
        post(:create, :user => @user_params, :send_welcome_email => "1")
        assert_sent_email
      end

      should "not send an email if :send_welcome_mail is not checked" do
        post(:create, :user => @user_params)
        assert_did_not_send_email
      end
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
