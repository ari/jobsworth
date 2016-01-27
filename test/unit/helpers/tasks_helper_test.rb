require "test_helper"

class TasksHelperTest < ActionView::TestCase
include ApplicationHelper
  setup do
    @user = User.make
    @project = Project.make(:company => @user.company)
    @project_temp = Project.make(:company => @user.company)
    #create two projects for the same user, one with create permission
    perm = ProjectPermission.new(:project => @project, :user => @user)
    perm.remove('all')
    perm.set('comment')
    perm.set('see_unwatched')
    #create permission
    perm.set('create')
    perm.save!
    perm_temp = ProjectPermission.new(:project => @project_temp, :user => @user)
    perm_temp.remove('all')
    perm_temp.set('comment')
    perm_temp.set('see_unwatched')
    perm_temp.save!
  end

  should "Project drop down lists only projects user have create or edit permission for" do
    @task =  TaskRecord.new(:company => @project.company)
    @options = options_for_user_projects(@task, @user)
    assert @options.to_s.match(@project.id.to_s).present?
    assert !(@options.to_s.match(@project_temp.id.to_s).present?)
  end
end
