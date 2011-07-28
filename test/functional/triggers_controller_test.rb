require 'test_helper'

class TriggersControllerTest < ActionController::TestCase
  signed_in_admin_context do
    setup do
      @user.admin=false
      @user.save!
      assert !@user.admin?
    end

    should "be redirected" do
      get :index
      assert_redirected_to "/tasks"
    end
  end

  signed_in_admin_context do
    setup do
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
               :task_filter_id => filter.id, :event_id => 1 })
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
        put :update, :id => @trigger.to_param, :trigger => { :event_id => 1 }
        assert_redirected_to triggers_path
        assert_equal 1, @trigger.reload.event_id
      end
    end
  end
end
