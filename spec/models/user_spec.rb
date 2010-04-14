require 'spec_helper'

describe User do
  fixtures :users, :projects, :project_permissions
  before(:each) do
    @user=users(:admin)
  end
  describe "method can?" do
    it "should accept 'see_unwatched' " do
      @user.can?(@user.projects.first, 'see_unwatched').should be_true
    end
    it "should accept :'see_unwatched'" do
      @user.can?(@user.projects.first, :see_unwatched).should be_true
    end
  end
end
