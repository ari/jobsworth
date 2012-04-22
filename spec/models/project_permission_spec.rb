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





# == Schema Information
#
# Table name: project_permissions
#
#  id                :integer(4)      not null, primary key
#  company_id        :integer(4)
#  project_id        :integer(4)
#  user_id           :integer(4)
#  created_at        :datetime
#  can_comment       :boolean(1)      default(FALSE)
#  can_work          :boolean(1)      default(FALSE)
#  can_report        :boolean(1)      default(FALSE)
#  can_create        :boolean(1)      default(FALSE)
#  can_edit          :boolean(1)      default(FALSE)
#  can_reassign      :boolean(1)      default(FALSE)
#  can_close         :boolean(1)      default(FALSE)
#  can_grant         :boolean(1)      default(FALSE)
#  can_milestone     :boolean(1)      default(FALSE)
#  can_see_unwatched :boolean(1)      default(TRUE)
#
# Indexes
#
#  fk_project_permissions_company_id     (company_id)
#  project_permissions_project_id_index  (project_id)
#  project_permissions_user_id_index     (user_id)
#

