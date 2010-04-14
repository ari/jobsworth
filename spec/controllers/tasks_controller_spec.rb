require 'spec_helper'

describe TasksController do
  describe "logged in user with can_only_see_watched permission" do
    before(:each) do
    end
    describe "GET list.xml" do
      before(:each) do
        get :list, :format=>'xml'
      end
      it "should include only watched tasks"
    end
  end
  describe "logged in user without can_only_see_watched permission" do
    describe "GET list.xml" do
      before(:each) do
        get :list, :format=>'xml'
      end
      it "should inlcude all tasks"
    end
  end
end
