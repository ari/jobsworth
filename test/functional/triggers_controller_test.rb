require 'test_helper'

class TriggersControllerTest < ActionController::TestCase
  context "a non-admin logged in user" do
    setup do
      @user = login
      @user.admin=false
      @user.save!
      assert !@user.admin?
    end

    should "be redirected" do
      get :index
      assert_redirected_to "/tasks/list"
    end
  end

  context "a logged in admin user" do
    setup do
      @user = login
      @user.update_attributes(:admin => 1)
      assert @user.admin?
    end

    should "get index" do
      get :index
      assert_response :success
      assert_not_nil assigns(:triggers)
    end

    should "get new" do
      get :new
      assert_response :success
      assert_not_nil assigns(:trigger)
    end

    should "create trigger" do
      filter = TaskFilter.make(:user => @user, :company => @user.company)

      assert_difference('Trigger.count') do
        post(:create, :trigger => {
               :task_filter_id => filter.id, :fire_on => "create" })
      end

      assert_not_nil assigns(:trigger)
      assert_redirected_to triggers_path
    end

    context "with an existing trigger" do
      setup do
        @trigger = Trigger.make(:company => @user.company)
      end

      should "destroy trigger" do
        assert_difference('Trigger.count', -1) do
          delete :destroy, :id => @trigger.to_param
        end
        assert_redirected_to triggers_path
      end

      should "get edit" do
        get :edit, :id => @trigger.to_param
        assert_response :success
      end

      should "update trigger" do
        put :update, :id => @trigger.to_param, :trigger => { :fire_on => "AAAA" }
        assert_redirected_to triggers_path
        assert_equal "AAAA", @trigger.reload.fire_on
      end
    end
  end
end
