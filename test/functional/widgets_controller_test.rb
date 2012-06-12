require "test_helper"

class WidgetsControllerTest < ActionController::TestCase

  signed_in_admin_context do
    setup do
      @widget = Widget.make(
        :user => @user,
        :company => @user.company,
        :configured => true,
        :name =>  "Top Tasks",
        :number => 5,
        :widget_type => 0,
        :column => 0,
        :position => 0)

      assert_not_nil @widget
    end

    should "be able to add widget" do
      get :add
      assert_response :success
    end

    should "be able to create widget" do
      assert_difference "Widget.count", 1 do
        post :create, :widget=>{"name"=>"Active Tasks", "widget_type"=>"10"}, :format => "js"
        assert_response :success
      end
    end

    should "be able to edit widget" do
      get :edit, :id => @widget.to_param
      assert_response :success
    end

    should "be able to update widget" do
      assert_equal 5, @widget.number
      assert_equal 'priority', @widget.order_by
      post :update, :id => @widget.to_param, :widget=>{"name"=>"Top Tasks", "number"=>"3", "order_by"=>"date", "mine"=>"true", "filter_by"=>"0"}
      @widget.reload
      assert_equal 3, @widget.number
      assert_equal 'date', @widget.order_by
      assert_response :success
    end

    should "be able to destroy widget" do
      assert_difference "Widget.count", -1 do
        delete :destroy, :id => @widget.to_param, :format => "js"
        assert_response :success
      end
    end

    should "be able to show comments widget with worklog.event_log == nil" do
      widget = Widget.make(
        :user => @user,
        :company => @user.company,
        :configured => true,
        :filter_by => "0",
        :mine => false,
        :name =>  "Task comments",
        :number => 5,
        :widget_type => 6,
        :column => 0,
        :position => 0
      )
      worklog = WorkLog.make(:user => @user, :company => @user.company, :event_log => nil)
      assert_nil worklog.event_log

      get :show, :id => widget.id     
      assert_response :success
    end
  end

end

