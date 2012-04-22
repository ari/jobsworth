require "test_helper"

class ProjectFolderTest < ActiveRecord::TestCase
  fixtures :project_folders

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end







# == Schema Information
#
# Table name: project_folders
#
#  id         :integer(4)      not null, primary key
#  name       :string(255)
#  project_id :integer(4)
#  parent_id  :integer(4)
#  created_at :datetime
#  company_id :integer(4)
#
# Indexes
#
#  index_project_folders_on_parent_id   (parent_id)
#  index_project_folders_on_project_id  (project_id)
#

