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
      put(:update, :id => @user.id,
           :user => { :name => "test", :admin => 1, :customer_id => customer.id },
           :emails => {@user.email_addresses.first.id.to_s => {"default"=>"1", "email"=>@user.email}},
           :new_emails => [{"email"=>"my@yahoo.com"}, {"email"=>"my@gmail.com"}])

      @user.reload
      assert @user.email_addresses.collect(&:email).include? "my@yahoo.com"
      assert @user.email_addresses.collect(&:email).include? "my@gmail.com"
      assert_redirected_to edit_user_path(@user)
    end

    context "creating a user" do
      setup do
        @customer = @user.company.customers.first
        new_user = User.make_unsaved(:customer_id => @customer.id, :company => @user.company)
        @user_params = new_user.attributes.with_indifferent_access.except(:id, :uuid, :autologin, User::ACCESS_CONTROL_ATTRIBUTES, :company_id, :encrypted_password, :password_salt, :reset_password_token, :remember_token, :remember_created_at, :reset_password_sent_at)

        ActionMailer::Base.deliveries.clear
      end

      should "be able to create a user" do
        email_addresses_count = EmailAddress.count
        assert_difference 'User.count', +1 do
          post(:create, :user => @user_params,
               :new_emails=>[{"default"=>"1", "email"=>"first@mine.com"}, {"email"=>"second@mine.com"}])
        end
        assert_equal email_addresses_count + 2, EmailAddress.count
        created = assigns(:user)
        assert !created.new_record?
        assert_redirected_to edit_user_path(created)
      end

      should "send a welcome email to primary email if :send_welcome_mail is checked" do
        post(:create, :user => @user_params, :send_welcome_email => "1",
             :new_emails=>[{"default"=>"1", "email"=>"myemail@gmail.com"}, {"email"=>"anothermail@yahoo.com"}])
        assert_equal %w(anothermail@yahoo.com myemail@gmail.com), assigns(:user).email_addresses.collect(&:email).sort
        assert_equal "myemail@gmail.com", assigns(:user).primary_email
        assert_equal 1, ActionMailer::Base.deliveries.size
        assert_equal %w(myemail@gmail.com), ActionMailer::Base.deliveries.first.to
      end

      should "not send an email if :send_welcome_mail is not checked" do
        size_before = ActionMailer::Base.deliveries.size
        post(:create, :user => @user_params)
        assert ActionMailer::Base.deliveries.size == size_before
      end

      should "be unable to create a user using an already taken address" do
        user = User.make(:customer_id => @customer.id, :company => @user.company, :active => false)
        post :create, :user => @user_params, :new_emails => [{:email => user.email}]
        assert_equal flash[:error], "Email #{user.email} is already taken by #{user.name}"
      end

      should "be able to create a user and automatically link to the first matched unknown email address" do
        ea = EmailAddress.make
        post :create, :user => @user_params, :new_emails => [{:email => ea.email, :default => true}]
        assert_equal flash[:success], "User was successfully created. Remember to give this user access to needed projects."
        assert_equal assigns(:user), ea.reload.user
        assert_equal ea.email, assigns(:user).email
        assert ea.reload.default
      end

      should "be able to create a user and automatically link to the first matched orphaned email address with correct default value" do
        ea = EmailAddress.make
        post :create, :user => @user_params, :new_emails => [{:email => ea.email, :default => true}]
        assert_equal flash[:success], "User was successfully created. Remember to give this user access to needed projects."
        assert_equal assigns(:user).email, ea.email
        assert ea.reload.default
      end
    end

    context "updating a user" do
      setup do
        @customer = @user.company.customers.first
        @update_user = User.make(:customer_id => @customer.id, :company => @user.company)
        @user_params = @update_user.attributes.slice(:name, :password, :customer, :email, :date_format, :time_zone, :time_format, :username)
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

      should "be unable to update a user using an already taken address" do
        user = User.make(:customer_id => @customer.id, :company => @user.company)
        post :update, :id => @update_user.id, :user => @user_params, :emails => {@update_user.email_addresses.first.id.to_s => {:email => user.email}}
        assert_equal flash[:error], "Email #{user.email} has already been taken"
      end

      should "be unable to update a user adding an already taken address" do
        user = User.make(:customer_id => @customer.id, :company => @user.company)
        post :update, :id => @update_user.id, :user => @user_params, :new_emails => [{:email => user.email}]
        assert_equal flash[:error], "Email #{user.email} is already taken by #{user.name}"
      end

      should "be able to update a user and automatically link to the first matched unknown email address" do
        ea = EmailAddress.make
        post :update, :id => @update_user.id, :user => @user_params, :new_emails => [{:email => ea.email}]
        assert_equal flash[:success], "User was successfully updated."
        assert_equal @update_user, ea.reload.user
        assert !ea.default
      end

      should "be able to update a user and automatically link to the first matched unknown email address as default" do
        ea = EmailAddress.make
        post :update, :id => @update_user.id, :user => @user_params, :new_emails => [{:email => ea.email, :default => true}], :emails => {@update_user.email_addresses.first.id => {:email => @update_user.email, :default => false}}
        assert_equal flash[:success], "User was successfully updated."
        assert_equal @update_user, ea.reload.user
        assert ea.default
        assert_equal ea.email, @update_user.reload.email
      end

      should "be able to update a user and automatically link to the first matched orphaned email address with correct primary email" do
        ea = EmailAddress.make
        post :update, :id => @update_user.id, :user => @user_params, :emails => {@update_user.email_addresses.first.id.to_s => {:email => ea.email, :default => true}}
        assert_equal flash[:success], "User was successfully updated."
        assert_equal @update_user.reload.email, ea.email
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
      assert_redirected_to "/users/edit_preferences"
      assert_equal "Only admins can edit users.", flash[:error]
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
