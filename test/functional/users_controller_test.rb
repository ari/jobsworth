require "test_helper"

class UsersControllerTest < ActionController::TestCase
  fixtures(:users, :email_addresses)

  signed_in_admin_context do

    should "should render edit" do
      other = User.make(:company => @user.company)
      get :edit, :id => other.id
      assert_response :success
    end

    should "redirect /update to /clients/edit" do
      customer = @user.company.customers.first
      assert_equal "admin@clockingit.com", @user.email
      post(:update, :id => @user.id,
           :user => { :name => "test", :customer_id => customer.id },
           :emails => {email_addresses(:admin_email_1).id.to_s => {"default"=>"", "email"=>email_addresses(:admin_email_1).email},
                       email_addresses(:admin_email_3).id.to_s => {"default"=>"1", "email"=>email_addresses(:admin_email_3).email}},
           :new_emails => [{"email"=>"my@yahoo.com"}, {"email"=>"my@gmail.com"}])

      @user.reload
      assert_equal "newadminemail@clockingit.com", @user.email
      assert_equal %w(admin@clockingit.com my@gmail.com my@yahoo.com newadminemail@clockingit.com), @user.email_addresses.collect(&:email).sort
      assert_redirected_to(:id => customer.id, :anchor => "users",
                           :controller => "customers", :action => "edit")
    end

    context "creating a user" do
      setup do
        @customer = @user.company.customers.first
        new_user = User.make_unsaved(:customer_id => @customer.id, :company => @user.company)
        @user_params = new_user.attributes

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
        assert_redirected_to :action => "edit", :id => created.id
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
        post :create, :user => @user_params, :new_emails => [{:email => ea.email}]
        assert_equal flash[:success], "User was successfully created. Remember to give this user access to needed projects."
        assert_equal assigns(:user), ea.reload.user
      end
    end

    context "updating a user" do
      setup do
        @customer = @user.company.customers.first
        @update_user = User.make(:customer_id => @customer.id, :company => @user.company)
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
      end

      should "be unable to update a user using an already taken address" do
        user = User.make(:customer_id => @customer.id, :company => @user.company)
        post :update, :id => @update_user.id, :user => @update_user.attributes, :emails => {@update_user.email_addresses.first.id.to_s => {:email => user.email}}
        assert_equal flash[:error], "Email #{user.email} has already been taken"
      end

      should "be unable to update a user adding an already taken address" do
        user = User.make(:customer_id => @customer.id, :company => @user.company)
        post :update, :id => @update_user.id, :user => @update_user.attributes, :new_emails => [{:email => user.email}]
        assert_equal flash[:error], "Email #{user.email} is already taken by #{user.name}"
      end

      should "be able to update a user and automatically link to the first matched unknown email address" do
        ea = EmailAddress.make
        post :update, :id => @update_user.id, :user => @update_user.attributes, :new_emails => [{:email => ea.email}]
        assert_equal flash[:success], "User was successfully updated."
        assert_equal @update_user, ea.reload.user
      end
    end
  end

  context "a logged in non-admin user" do
    setup do
       @user = users(:admin)
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

    should "be able to save user preferences" do
      post(:set_preference, :name => "test_pref", :value => [ 1, 2 ].to_json)
      assert_response :success
      assert_equal "[1,2]", @user.reload.preference("test_pref")
    end
  end

end
