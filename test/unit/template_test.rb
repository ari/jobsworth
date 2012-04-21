require "test_helper"

class TemplateTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
  should "not include templates in user.tasks association" do
    user=User.make
    project=Project.make(:company=>user.company)
    task= Task.make(:company=>user.company, :owners=>[user])
    template= Template.create(:name=>'some', :description=>'asdasd', :project=>project, :company=>user.company, :owners=>[user])
    assert_equal user.tasks, [task]
    assert !user.tasks.include?(template)
  end
end









# == Schema Information
#
# Table name: tasks
#
#  id                 :integer(4)      not null, primary key
#  name               :string(200)     default(""), not null
#  project_id         :integer(4)      default(0), not null
#  position           :integer(4)      default(0), not null
#  created_at         :datetime        not null
#  due_at             :datetime
#  updated_at         :datetime        not null
#  completed_at       :datetime
#  duration           :integer(4)      default(1)
#  hidden             :integer(4)      default(0)
#  milestone_id       :integer(4)
#  description        :text
#  company_id         :integer(4)
#  priority           :integer(4)      default(0)
#  updated_by_id      :integer(4)
#  severity_id        :integer(4)      default(0)
#  type_id            :integer(4)      default(0)
#  task_num           :integer(4)      default(0)
#  status             :integer(4)      default(0)
#  creator_id         :integer(4)
#  hide_until         :datetime
#  scheduled_at       :datetime
#  scheduled_duration :integer(4)
#  scheduled          :boolean(1)      default(FALSE)
#  worked_minutes     :integer(4)      default(0)
#  type               :string(255)     default("Task")
#  weight             :integer(4)      default(0)
#  weight_adjustment  :integer(4)      default(0)
#  wait_for_customer  :boolean(1)      default(FALSE)
#  estimate           :decimal(5, 2)
#
# Indexes
#
#  index_tasks_on_type_and_task_num_and_company_id  (type,task_num,company_id) UNIQUE
#  tasks_company_id_index                           (company_id)
#  tasks_due_at_idx                                 (due_at)
#  index_tasks_on_milestone_id                      (milestone_id)
#  tasks_project_completed_index                    (project_id,completed_at)
#  tasks_project_id_index                           (project_id,milestone_id)
#

