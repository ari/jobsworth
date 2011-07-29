require 'spec_helper'

describe TutorialController do
  render_views

  describe "GET 'hide_welcome'" do
    context "When the user is signed in" do
      before :each do
        sign_in_normal_user
      end

      it "should update the 'seen_welcome' flag on the logged user" do
        get :hide_welcome
        @logged_user.reload
        @logged_user.seen_welcome.should == 1  
      end

      it "should display a notification message" do
        get :hide_welcome
        flash['notice'].should match 'Tutorial hidden. It will no longer be shown in the menu.'
      end

      it "should redirect to the 'index' action" do
        get :hide_welcome
        response.should redirect_to root_path
      end
    end
  end

  describe "GET 'welcome'" do
    context "When the user is signed in" do
      before :each do
        sign_in_normal_user
      end

      context "When the user is still in the tutorial" do
        before :each do
          controller.stub!(:user_has_completed_tutorial?).and_return false

          # The following instance vars are required by the view (not cool brah)
          controller.instance_variable_set('@projects_count', 0)
          controller.instance_variable_set('@tasks_count', 0)
          controller.instance_variable_set('@work_count', 0)
          controller.instance_variable_set('@completed_count', 0)
          controller.instance_variable_set('@users_count', 0)
        end

        it "should not update the seen_welcome flag on the logged user" do
          get :welcome
          @logged_user.reload
          @logged_user.seen_welcome.should == 0
        end
      end

      context "When the user has completed the tutorial" do
        before :each do
          controller.stub!(:user_has_completed_tutorial?).and_return true

          # The following instance vars are required by the view (not cool brah)
          controller.instance_variable_set('@projects_count', 1)
          controller.instance_variable_set('@tasks_count', 1)
          controller.instance_variable_set('@work_count', 1)
          controller.instance_variable_set('@completed_count', 1)
          controller.instance_variable_set('@users_count', 2)
        end

        it "should update the seen_welcome flag on the logged user" do
          get :welcome
          @logged_user.reload
          @logged_user.seen_welcome.should == 1 
        end
      end

    end
  end
end
