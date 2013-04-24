require "test_helper"

class UsersControllerTest < ActionController::TestCase
  signed_in_admin_context do
    should "should render edit" do
      other = User.make(:company => @user.company)
      get :edit, :id => other.id
      assert_response :success
    end

    should "redirect /update to /users/edit" do
      customer = @user.company.customers.first
      put(:update, :id => @user.id, :user => { :name => "test", :admin => 1, :customer_id => customer.id })

      @user.reload
      assert_redirected_to edit_user_path(@user)
    end

    context "creating a user" do
      setup do
        @customer = @user.company.customers.first
        new_user = User.make_unsaved(:customer_id => @customer.id, :company => @user.company)
        @user_params = new_user.attributes.with_indifferent_access.slice(:name, :password, :customer_id, :date_format, :time_zone, :time_format, :username)

        ActionMailer::Base.deliveries.clear
      end

      should "be able to create a user" do
        email_addresses_count = EmailAddress.count
        assert_difference 'User.count', +1 do
          post(:create, :user => @user_params, "email"=>"second@mine.com")
        end
        assert_equal email_addresses_count + 1, EmailAddress.count
        created = assigns(:user)
        assert !created.new_record?
        assert_redirected_to edit_user_path(created)
      end

      should "send a welcome email to primary email if :send_welcome_mail is checked" do
        post(:create, :user => @user_params, :send_welcome_email => "1", "email"=>"anothermail@yahoo.com")
        assert_equal %w(anothermail@yahoo.com), assigns(:user).email_addresses.collect(&:email).sort
        assert_equal "anothermail@yahoo.com", assigns(:user).email
        assert_equal 1, ActionMailer::Base.deliveries.size
        assert_equal %w(anothermail@yahoo.com), ActionMailer::Base.deliveries.first.to
      end

      should "not send an email if :send_welcome_mail is not checked" do
        size_before = ActionMailer::Base.deliveries.size
        post(:create, :user => @user_params, :email => %w(anothermail@yahoo.com))
        assert ActionMailer::Base.deliveries.size == size_before
      end

      should "be unable to create a user using an already taken address" do
        user = User.make(:customer_id => @customer.id, :company => @user.company, :active => false)
        post :create, :user => @user_params, :email => user.email
        assert_equal flash[:error], "Email #{user.email} has already been taken by #{user.name}"
      end

      should "be able to create a user and automatically link to the first matched unknown email address" do
        ea = EmailAddress.make(:company => @user.company)
        post :create, :user => @user_params, :email => ea.email
        assert_equal flash[:success], I18n.t('flash.notice.model_created', model: User.model_name.human) +
                                      I18n.t('hint.user.add_permissions')
        assert_equal assigns(:user), ea.reload.user
        assert_equal ea.email, assigns(:user).email
        assert ea.reload.default
      end

      should "be able to create a user and automatically link to the first matched orphaned email address with correct default value" do
        ea = EmailAddress.make(:company => @user.company)
        post :create, :user => @user_params, :email => ea.email
        assert_equal flash[:success], I18n.t('flash.notice.model_created', model: User.model_name.human) +
                                      I18n.t('hint.user.add_permissions')
        assert_equal assigns(:user).email, ea.email
        assert ea.reload.default
      end
    end

    context "updating a user" do
      setup do
        @customer = @user.company.customers.first
        @update_user = User.make(:customer_id => @customer.id, :company => @user.company)
        @user_params = @update_user.attributes.with_indifferent_access.slice(:name, :password, :customer, :date_format, :time_zone, :time_format, :username)
      end

      should "be able to mark user as active" do
        user = User.make(:customer_id => @customer.id, :company => @user.company, :active => false)
        post(:update, :user => {:active => true}, :id => user.id)
        assert user.reload.active == true
      end

      should "be able to mark user as inactive" do
        user = User.make(:customer_id => @customer.id, :company => @user.company, :active => true)
        post(:update, :user => {:active => false}, :id => user.id)
        assert user.reload.active == false
        assert_redirected_to edit_user_path(user)
      end
    end
  end

  context "a logged in non-admin user" do
    setup do
       @user = User.make(:admin)
       @user.update_attribute(:admin, false)
       sign_in @user
       @request.session[:user_id] = session["warden.user.user.key"][1]
       @user.company.create_default_statuses
    end

    should "restrict edit page to admin user" do
      other = User.make(:company => @user.company)
      get :edit, :id => other.id
      assert_redirected_to edit_user_path(@user)
      assert_equal "Only admins may access this area.", flash[:error]
    end
  end

  context "search users" do
    setup do
      @user = User.make(:name => "Smith Gleid")
      sign_in @user
      @user.company.create_default_statuses
    end

    should "be able to search users" do
      get :auto_complete_for_user_name, :term  => "Smith"
      assert_response :success
      assert response.body.include?("Smith Gleid")
    end

    should "be able to search users with no customer" do
      User.make(:name => "John Lee", :company => @user.company, :customer => nil)
      get :auto_complete_for_user_name, :term  => "John"
      assert_response :success
      assert response.body.include?("John Lee")
    end
  end

end
