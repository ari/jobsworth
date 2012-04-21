require "test_helper"

class ProjectPermissionTest < ActiveRecord::TestCase
  fixtures :project_permissions

  # Replace this with your real tests.
  def test_truth
    assert true
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

