require "test_helper"

class MilestoneTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
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
#  scheduled_at    :datetime
#  scheduled       :boolean(1)      default(FALSE)
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

