require "test_helper"

class MilestoneTest < ActiveSupport::TestCase
  setup do
    @user = User.make
    @project = project_with_some_tasks(@user, :make_milestones => true)
    @milestone = @project.milestones.last
  end

  test "auto close locked milestone if all tasks are resolved" do
    @milestone.update_attributes(:status_name => :locked)

    @milestone.tasks.each do |t|
      t.update_attributes(:status => 1, :completed_at => Time.now)
    end

    assert_equal :closed, @milestone.reload.status_name
  end

  test "auto close locked milestone if all tasks are resolved triggered on changing milestone status" do
    @milestone.tasks.clear
    @milestone.update_attributes(:status_name => :locked)
    assert_equal :closed, @milestone.reload.status_name
  end
end








# == Schema Information
#
# Table name: milestones
#
#  id              :integer(4)      not null, primary key
#  company_id      :integer(4)
#  project_id      :integer(4)
#  user_id         :integer(4)
#  name            :string(255)
#  description     :text
#  due_at          :datetime
#  position        :integer(4)
#  completed_at    :datetime
#  total_tasks     :integer(4)      default(0)
#  completed_tasks :integer(4)      default(0)
#  updated_at      :datetime
#  created_at      :datetime
#
# Indexes
#
#  milestones_company_project_index  (company_id,project_id)
#  milestones_company_id_index       (company_id)
#  milestones_project_id_index       (project_id)
#  fk_milestones_user_id             (user_id)
#

