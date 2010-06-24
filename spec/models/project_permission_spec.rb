require 'spec_helper'

describe ProjectPermission do

  before(:each) do
    @permission=ProjectPermission.create!
  end
  it "should return array of available permissions in ProjectPermission.permissions" do
    ProjectPermission.permissions.should == ['comment', 'work', 'close', 'see_unwatched', 'create', 'edit', 'reassign', 'milestone', 'report', 'grant', 'all']
  end
  context ".message_for(permission)" do
    it "should return access denied message for permission" do
      ProjectPermission.message_for('comment').should_not be_empty
    end
    it "should raise exception if  message don't exist" do
      lambda { ProjectPermission.message_for('this permmission not exist')}.should raise_error
    end
  end
  it "should have can_see_unwatched permission set to true by default" do
    @permission.can_see_unwatched.should be_true
  end
  context "when can_see_unwatched is false" do
    before(:each) do
      @permission.can_see_unwatched=false
      @permission.save!
    end
    it "should set can_see_unwatched using ProjectPermission#set('see_unwatched')" do
      @permission.set('see_unwatched')
      @permission.can?('see_unwatched').should be_true
    end
    it "should set can_see_unwatched using ProjectPermission#set('all')" do
      @permission.set('all')
      @permission.can?('see_unwatched').should be_true
    end
  end
  context "when can_see_unwatched is true" do
    before(:each) do
      @permission.can_see_unwatched=true
      @permission.save!
    end
    it "should remove can_see_unwatched using ProjectPermission#remove('see_unwatched')" do
      @permission.remove('see_unwatched')
      @permission.can?('see_unwatched').should_not be_true
    end
    it "should remove can_see_unwatched using ProjectPermission#remove('all')" do
      @permission.remove('all')
      @permission.can?('see_unwatched').should_not be_true
    end
  end
end
